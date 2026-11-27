import SwiftUI

struct MoviesView: View {
    @StateObject private var viewModel: BoxOfficeViewModel
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
                            NavigationLink(destination: DetailsView(item: item)) {
                                            FilmSerieItemView(item: item)
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
                // Si le champ est vide, on recharge les films populaires (optionnel)
                guard !searchText.isEmpty else { return }
                
                do {
                    // Met la tâche en pause pendant 0.5 seconde (500 000 000 nanosecondes)
                    try await Task.sleep(nanoseconds: 500_000_000)
                    
                    // Si l'utilisateur n'a pas tapé de nouvelle lettre pendant ce délai, la requête se lance
                    await viewModel.load(query: searchText)
                } catch {
                    // L'utilisateur a tapé une nouvelle lettre avant les 0.5s.
                    // Task.sleep lève une erreur (CancellationError) et la requête est annulée.
                }
            }
        }
    }
}
