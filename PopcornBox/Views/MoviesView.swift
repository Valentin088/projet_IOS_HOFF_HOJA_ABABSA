import SwiftUI

struct MoviesView: View {
    @StateObject private var viewModel: BoxOfficeViewModel
    @StateObject private var dataViewModel = UserDataViewModel()
    @State private var searchText = ""

    init() {
        let client: TMDBProviding = UITesting.isEnabled ? UITesting.Client() : TMDBClient()
        _viewModel = StateObject(wrappedValue: BoxOfficeViewModel(mediaType: .movie, client: client))
    }

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Chargement des films...")
                        .accessibilityIdentifier("movies.loading")
                case .loaded:
                    if viewModel.items.isEmpty {
                        Text("Aucun film trouvé")
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("movies.empty")
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
                            .accessibilityIdentifier("movies.row.\(item.id)")
                        }
                        .accessibilityIdentifier("movies.list")
                    }
                case .error(let message):
                    VStack(spacing: 10) {
                        Text("Une erreur est survenue")
                            .font(.headline)
                            .accessibilityIdentifier("movies.error.title")
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("movies.error.message")
                    }
                    .accessibilityIdentifier("movies.error")
                }
            }
            .navigationTitle("Films")
            .searchable(text: $searchText, prompt: "Rechercher un film...")
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
