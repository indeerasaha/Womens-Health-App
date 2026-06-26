import SwiftUI
import SwiftData

/// Manual food entry — for foods you can't find in a database.
struct ManualFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var caloriesText: String = ""
    @State private var meal: Meal = .snack

    private var calories: Int? { Int(caloriesText) }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (calories ?? 0) > 0
    }

    var body: some View {
        Form {
            Section("What did you eat?") {
                TextField("e.g. Homemade granola", text: $name)
                    .textInputAutocapitalization(.sentences)
            }
            Section("Calories") {
                TextField("e.g. 220", text: $caloriesText)
                    .keyboardType(.numberPad)
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
        .navigationTitle("Enter manually")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Log", action: save)
                    .disabled(!canSave)
            }
        }
    }

    private func save() {
        guard let calories, canSave else { return }
        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespaces),
            caloriesPer100g: Double(calories),
            amountGrams: 100,
            meal: meal
        )
        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    NavigationStack { ManualFoodEntryView() }
}
