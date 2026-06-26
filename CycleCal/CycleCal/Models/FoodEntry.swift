import Foundation
import SwiftData

/// A single logged food item, persisted with SwiftData.
///
/// Schema notes:
/// - Nutrition is stored per 100g (USDA / Open Food Facts convention).
/// - `amountGrams` is how much the user actually ate.
/// - Total calories for this entry = `caloriesPer100g * amountGrams / 100`.
/// - For now the Add Food UI lets users enter total calories directly, and we
///   back into the per-100g value. When we add real food sources later
///   (USDA, OFF), the per-100g field comes pre-populated and amountGrams
///   becomes the variable the user changes.
@Model
final class FoodEntry {
    var name: String
    var caloriesPer100g: Double
    var amountGrams: Double
    var meal: Meal
    var loggedAt: Date

    init(
        name: String,
        caloriesPer100g: Double,
        amountGrams: Double,
        meal: Meal,
        loggedAt: Date = .now
    ) {
        self.name = name
        self.caloriesPer100g = caloriesPer100g
        self.amountGrams = amountGrams
        self.meal = meal
        self.loggedAt = loggedAt
    }

    /// Total calories for this entry.
    var totalCalories: Int {
        Int((caloriesPer100g * amountGrams / 100).rounded())
    }
}

/// Which meal a food entry belongs to. Stored as a string under the hood.
enum Meal: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
