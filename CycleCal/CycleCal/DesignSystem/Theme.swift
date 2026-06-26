import SwiftUI

/// Central design tokens. Define values here once and reference everywhere
/// so the UI stays consistent and is trivial to re-theme later.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 12
        static let button: CGFloat = 10
    }
}

extension Color {
    /// App accent. Swap this one value to re-tint the whole app.
    static let appAccent = Color(red: 0.85, green: 0.36, blue: 0.50)
    static let cardBackground = Color(.secondarySystemBackground)
}
