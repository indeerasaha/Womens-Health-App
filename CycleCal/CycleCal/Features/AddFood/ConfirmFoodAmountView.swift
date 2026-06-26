import SwiftUI
import SwiftData

/// Shown after a search result is picked. Fetches the full detail (which has
/// richer portion data than the search result), caches the food locally, and
/// lets the user choose how much they actually ate.
struct ConfirmFoodAmountView: View {
    let searchItem: USDAFoodSearchItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var food: Food?
    @State private var loadError: String?

    @State private var selectedPortionID: String?  // nil = custom grams
    @State private var portionCount: Double = 1
    @State private var customGrams: Double = 100
    @State private var meal: Meal = currentMealGuess()

    private var grams: Double {
        if let id = selectedPortionID,
           let portion = food?.portions.first(where: { $0.id == id }) {
            return portion.gramWeight * portionCount
        }
        return customGrams
    }

    private var totalCalories: Int {
        guard let food else { return 0 }
        return Int((food.caloriesPer100g * grams / 100).rounded())
    }

    var body: some View {
        Group {
            if let food {
                form(for: food)
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn't load food",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(searchItem.description)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDetail() }
    }

    @ViewBuilder
    private func form(for food: Food) -> some View {
        Form {
            Section("Calories") {
                LabeledContent("Total", value: "\(totalCalories) cal")
                    .font(.title3)
            }

            Section("Amount") {
                if !food.portions.isEmpty {
                    Picker("Measure", selection: $selectedPortionID) {
                        ForEach(food.portions) { portion in
                            Text(portion.description)
                                .tag(Optional(portion.id))
                        }
                        Text("Grams (custom)").tag(Optional<String>.none)
                    }

                    if selectedPortionID != nil {
                        Stepper(
                            value: $portionCount,
                            in: 0.25...20,
                            step: 0.25
                        ) {
                            Text("Servings: \(formatted(portionCount))")
                        }
                    } else {
                        gramsField
                    }
                } else {
                    gramsField
                }
            }

            Section("Meal") {
                Picker("Meal", selection: $meal) {
                    ForEach(Meal.allCases) { meal in
                        Text(meal.displayName).tag(meal)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Log") { save(food: food) }
                    .disabled(grams <= 0)
            }
        }
    }

    private var gramsField: some View {
        HStack {
            Text("Grams")
            Spacer()
            TextField("g", value: $customGrams, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
    }

    // MARK: - Actions

    private func loadDetail() async {
        // Check cache first.
        let id = String(searchItem.fdcId)
        let predicate = #Predicate<Food> { $0.sourceID == id }
        let descriptor = FetchDescriptor<Food>(predicate: predicate)
        if let cached = try? modelContext.fetch(descriptor).first {
            food = cached
            applyDefaultPortion()
            return
        }

        // Fetch and cache.
        do {
            let detail = try await USDAClient.shared.detail(fdcId: searchItem.fdcId)
            guard let newFood = detail.toLocalFood() else {
                loadError = "USDA returned no nutrition data for this food."
                return
            }
            modelContext.insert(newFood)
            food = newFood
            applyDefaultPortion()
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func applyDefaultPortion() {
        // Prefer the first household portion if available; otherwise grams.
        if let first = food?.portions.first {
            selectedPortionID = first.id
        } else {
            selectedPortionID = nil
            customGrams = 100
        }
    }

    private func save(food: Food) {
        let entry = FoodEntry(
            name: food.name,
            caloriesPer100g: food.caloriesPer100g,
            amountGrams: grams,
            meal: meal
        )
        modelContext.insert(entry)
        dismiss()
        // The chooser is the presenter; dismissing this view pops the nav stack
        // but leaves the chooser sheet up. The chooser sheet is dismissed by
        // DailyLogView when the user closes it, OR we could dismiss programmatically.
        // For now: tapping Log returns to the search list, which feels right
        // for logging multiple foods in a row.
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded()
            ? String(Int(value))
            : String(format: "%.2f", value)
    }

    /// Guess the meal based on the current hour. Saves a tap.
    private static func currentMealGuess() -> Meal {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 4..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<21: return .dinner
        default: return .snack
        }
    }
}
