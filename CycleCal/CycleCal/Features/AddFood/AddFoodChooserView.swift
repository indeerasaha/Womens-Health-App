import SwiftUI

/// Root of the Add Food flow. Two paths from here: search a database, or
/// enter something manually.
struct AddFoodChooserView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    FoodSearchView()
                } label: {
                    Label("Search foods", systemImage: "magnifyingglass")
                }

                NavigationLink {
                    ManualFoodEntryView()
                } label: {
                    Label("Enter manually", systemImage: "square.and.pencil")
                }
            }
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddFoodChooserView()
}
