import SwiftUI
import SwiftData

@main
struct CycleCalApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: FoodEntry.self)
    }
}
