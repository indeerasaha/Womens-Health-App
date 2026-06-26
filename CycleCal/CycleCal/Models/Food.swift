import Foundation
import SwiftData

/// A food we know about. Stored per 100g, with optional household portions
/// (e.g. "1 cup = 245 g") for friendly amount entry.
///
/// Every food fetched from USDA / Open Food Facts gets persisted here on
/// first reference, so subsequent uses are local-only and offline.
@Model
final class Food {
    /// Where this food came from.
    var source: FoodSource
    /// External ID within that source (USDA fdcId as String, or OFF barcode).
    var sourceID: String
    /// Optional UPC/EAN; only branded products have this.
    var barcode: String?

    var name: String
    var brand: String?

    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double

    /// Household measures like "1 cup", "1 medium banana". May be empty.
    /// Stored inline as a value type — SwiftData persists these as a blob.
    var portions: [Portion]

    var fetchedAt: Date

    init(
        source: FoodSource,
        sourceID: String,
        barcode: String? = nil,
        name: String,
        brand: String? = nil,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        portions: [Portion] = [],
        fetchedAt: Date = .now
    ) {
        self.source = source
        self.sourceID = sourceID
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.portions = portions
        self.fetchedAt = fetchedAt
    }
}

enum FoodSource: String, Codable {
    case usda
    case openFoodFacts
    case manual
}

/// One household-style measure for a food (e.g. "1 cup = 245 g").
struct Portion: Codable, Hashable, Identifiable {
    var id: String { description }
    var description: String   // "1 cup", "1 medium banana"
    var gramWeight: Double    // grams in that portion
}
