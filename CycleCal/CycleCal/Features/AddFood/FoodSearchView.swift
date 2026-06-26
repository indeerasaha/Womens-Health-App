import SwiftUI

struct FoodSearchView: View {
    @State private var query: String = ""
    @State private var results: [USDAFoodSearchItem] = []
    @State private var phase: Phase = .idle
    @State private var searchTask: Task<Void, Never>?

    enum Phase: Equatable {
        case idle
        case searching
        case loaded
        case error(String)
    }

    var body: some View {
        List {
            switch phase {
            case .idle:
                if query.isEmpty {
                    ContentUnavailableView(
                        "Search USDA foods",
                        systemImage: "magnifyingglass",
                        description: Text("Try 'greek yogurt' or 'banana'.")
                    )
                }
            case .searching:
                HStack {
                    ProgressView()
                    Text("Searching…")
                        .foregroundStyle(.secondary)
                }
            case .loaded:
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(results) { item in
                        NavigationLink {
                            ConfirmFoodAmountView(searchItem: item)
                        } label: {
                            resultRow(item)
                        }
                    }
                }
            case .error(let message):
                ContentUnavailableView(
                    "Couldn't search",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Search foods")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: query) { _, newValue in
            scheduleSearch(for: newValue)
        }
    }

    private func resultRow(_ item: USDAFoodSearchItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.description)
                .font(.body)
                .lineLimit(2)
            HStack(spacing: 6) {
                if let brand = item.brandLabel {
                    Text(brand)
                }
                if let type = item.dataType {
                    Text("·").foregroundStyle(.tertiary)
                    Text(type)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    /// Debounce: wait 350ms after the user stops typing before searching.
    /// Cancels any in-flight task when the query changes.
    private func scheduleSearch(for newValue: String) {
        searchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            phase = .idle
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await runSearch(trimmed)
        }
    }

    private func runSearch(_ query: String) async {
        phase = .searching
        do {
            let items = try await USDAClient.shared.search(query: query)
            guard !Task.isCancelled else { return }
            results = items
            phase = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            phase = .error(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        FoodSearchView()
    }
}
