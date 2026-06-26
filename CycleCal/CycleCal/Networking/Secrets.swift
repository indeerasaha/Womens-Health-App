import Foundation

/// Reads values from `Secrets.plist`. The file is gitignored, so keys live
/// only on your machine. Add new secrets by adding rows to the plist.
enum Secrets {
    static let usdaAPIKey: String = value(for: "USDA_API_KEY")

    private static func value(for key: String) -> String {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization
                .propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String,
            !value.isEmpty
        else {
            assertionFailure("""
                Missing Secrets.plist or missing key '\(key)'. \
                Create Secrets.plist in the app target with this key.
                """)
            return ""
        }
        return value
    }
}
