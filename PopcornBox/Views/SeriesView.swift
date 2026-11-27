import SwiftUI

struct SeriesView: View {
    @StateObject private var viewModel: BoxOfficeViewModel
    @StateObject private var dataViewModel = UserDataViewModel()
    @State private var searchText = ""

    init() {
        let client: TMDBProviding = UITesting.isEnabled ? UITesting.Client() : TMDBClient()
        _viewModel = StateObject(wrappedValue: BoxOfficeViewModel(mediaType: .series, client: client))
    }

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Chargement des séries...")
                        .accessibilityIdentifier("series.loading")
                case .loaded:
                    if viewModel.items.isEmpty {
                        Text("Aucune série trouvée")
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("series.empty")
                    } else {
                        List(viewModel.items) { item in
                            let isFav = dataViewModel.favorites.contains { $0.itemId == item.id && $0.kind == item.kind }
                            NavigationLink(destination: DetailsView(item: item)) {
                                FilmSerieItemView(
                                    item: item,
                                    isFavorite: isFav,
                                    onToggleFavorite: {
                                        Task {
                                            await dataViewModel.toggleFavorite(item)
                                        }
                                    }
                                )
                            }
                            .accessibilityIdentifier("series.row.\(item.id)")
                        }
                        .accessibilityIdentifier("series.list")
                    }
                case .error(let message):
                    VStack(spacing: 10) {
                        Text("Une erreur est survenue")
                            .font(.headline)
                            .accessibilityIdentifier("series.error.title")
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("series.error.message")
                    }
                    .accessibilityIdentifier("series.error")
                }
            }
            .navigationTitle("Séries")
            .searchable(text: $searchText, prompt: "Rechercher une série...")
            .task {
                await viewModel.load()
            }

            .task(id: searchText) {
                guard !searchText.isEmpty else { return }

                do {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    await viewModel.load(query: searchText)
                } catch {
                }
            }
        }
    }
}
