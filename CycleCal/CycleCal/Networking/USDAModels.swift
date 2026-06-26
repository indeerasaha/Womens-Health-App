import Foundation

/// USDA nutrient IDs — these are stable across the API.
/// Reference: https://fdc.nal.usda.gov/
enum USDANutrientID {
    static let energyKcal = 1008
    static let protein    = 1003
    static let fat        = 1004
    static let carbs      = 1005
}

// MARK: - Search response

struct USDASearchResponse: Decodable {
    let foods: [USDAFoodSearchItem]
}

struct USDAFoodSearchItem: Decodable, Identifiable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let brandName: String?
    let brandOwner: String?
    let foodNutrients: [USDAFoodNutrient]?
    let foodMeasures: [USDAFoodMeasure]?

    var id: Int { fdcId }

    /// Best brand label to show, if any.
    var brandLabel: String? {
        brandName ?? brandOwner
    }
}

/// In search results, nutrients are flattened: nutrientId + value at top level.
struct USDAFoodNutrient: Decodable {
    let nutrientId: Int?
    let nutrientName: String?
    let value: Double?
    let unitName: String?
}

/// Search results expose portions as `foodMeasures`.
struct USDAFoodMeasure: Decodable {
    let disseminationText: String?
    let gramWeight: Double?
}

// MARK: - Detail response (used after a search result is selected)

struct USDAFoodDetail: Decodable {
    let fdcId: Int
    let description: String
    let brandName: String?
    let brandOwner: String?
    let dataType: String?
    let foodNutrients: [USDADetailNutrient]?
    let foodPortions: [USDAFoodPortion]?
}

/// Detail endpoint wraps the nutrient differently — nutrient info is nested.
struct USDADetailNutrient: Decodable {
    struct Nutrient: Decodable {
        let id: Int?
        let name: String?
        let unitName: String?
    }
    let nutrient: Nutrient?
    let amount: Double?
}

struct USDAFoodPortion: Decodable {
    let amount: Double?
    let gramWeight: Double?
    let portionDescription: String?
    let modifier: String?
    let measureUnit: USDAMeasureUnit?
}

struct USDAMeasureUnit: Decodable {
    let name: String?
}
