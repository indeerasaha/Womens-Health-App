import Foundation

/// Talks to USDA FoodData Central. Stateless; one shared instance is fine.
struct USDAClient {
    static let shared = USDAClient()

    private let baseURL = URL(string: "https://api.nal.usda.gov/fdc/v1")!
    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    enum ClientError: Error, LocalizedError {
        case badResponse(Int)
        case decoding(Error)
        case transport(Error)

        var errorDescription: String? {
            switch self {
            case .badResponse(let code): "USDA returned HTTP \(code)."
            case .decoding(let err): "Couldn't parse USDA response: \(err.localizedDescription)"
            case .transport(let err): "Network error: \(err.localizedDescription)"
            }
        }
    }

    // MARK: - Endpoints

    /// Search foods by free-text query. Prioritizes generic foods (Foundation,
    /// SR Legacy, Survey) over Branded so "yogurt" returns generic yogurt first.
    func search(query: String, pageSize: Int = 25) async throws -> [USDAFoodSearchItem] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("foods/search"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.usdaAPIKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            // Order matters for ranking: types listed first weight higher.
            URLQueryItem(name: "dataType",
                         value: "Foundation,SR Legacy,Survey (FNDDS),Branded"),
        ]

        let response: USDASearchResponse = try await get(components.url!)
        return response.foods
    }

    /// Fetch full detail for a food. Used after the user picks a search result,
    /// because foodPortions are richer here than in search results.
    func detail(fdcId: Int) async throws -> USDAFoodDetail {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("food/\(fdcId)"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: Secrets.usdaAPIKey),
        ]
        return try await get(components.url!)
    }

    // MARK: - Private

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw ClientError.badResponse(-1)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw ClientError.badResponse(http.statusCode)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw ClientError.decoding(error)
            }
        } catch let e as ClientError {
            throw e
        } catch {
            throw ClientError.transport(error)
        }
    }
}

// MARK: - Normalization into our local Food model

extension USDAFoodDetail {
    /// Convert a USDA detail response into our cached Food.
    /// Returns nil if the response is missing the calorie value we need.
    func toLocalFood() -> Food? {
        let kcal = nutrient(USDANutrientID.energyKcal) ?? 0
        let protein = nutrient(USDANutrientID.protein) ?? 0
        let carbs = nutrient(USDANutrientID.carbs) ?? 0
        let fat = nutrient(USDANutrientID.fat) ?? 0

        // USDA nutrient values on detail responses are per 100g for
        // Foundation / SR Legacy / Survey foods. Branded items vary; we
        // accept the value as-is for now and revisit if accuracy issues arise.
        guard kcal > 0 || protein > 0 || carbs > 0 || fat > 0 else {
            return nil
        }

        return Food(
            source: .usda,
            sourceID: String(fdcId),
            name: description,
            brand: brandName ?? brandOwner,
            caloriesPer100g: kcal,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            portions: normalizedPortions()
        )
    }

    private func nutrient(_ id: Int) -> Double? {
        foodNutrients?
            .first(where: { $0.nutrient?.id == id })?
            .amount
    }

    private func normalizedPortions() -> [Portion] {
        guard let foodPortions else { return [] }
        return foodPortions.compactMap { p -> Portion? in
            guard let grams = p.gramWeight, grams > 0 else { return nil }
            let description = humanReadable(p)
            guard !description.isEmpty else { return nil }
            return Portion(description: description, gramWeight: grams)
        }
    }

    private func humanReadable(_ p: USDAFoodPortion) -> String {
        // USDA returns portions in a few different shapes depending on data type.
        // Try the prebuilt description first, then assemble from parts.
        if let desc = p.portionDescription, !desc.isEmpty {
            return desc
        }
        var parts: [String] = []
        if let amount = p.amount {
            // Strip trailing .0 for whole numbers ("1 cup" not "1.0 cup").
            if amount == amount.rounded() {
                parts.append(String(Int(amount)))
            } else {
                parts.append(String(amount))
            }
        }
        if let unit = p.measureUnit?.name, unit != "undetermined" {
            parts.append(unit)
        }
        if let modifier = p.modifier, !modifier.isEmpty {
            parts.append(modifier)
        }
        return parts.joined(separator: " ")
    }
}
