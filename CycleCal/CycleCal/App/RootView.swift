import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DailyLogView()
                .tabItem {
                    Label("Today", systemImage: "fork.knife")
                }

            // Placeholder tabs — build these out later.
            Text("Cycle")
                .tabItem {
                    Label("Cycle", systemImage: "calendar")
                }

            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    RootView()
}
