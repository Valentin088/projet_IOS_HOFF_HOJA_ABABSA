import SwiftUI

struct SeriesView: View {
    @StateObject private var viewModel = BoxOfficeViewModel(mediaType: .series)
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Chargement des séries...")
                case .loaded:
                    if viewModel.items.isEmpty {
                        Text("Aucune série trouvée")
                            .foregroundColor(.secondary)
                    } else {
                        List(viewModel.items) { item in
                            NavigationLink(destination: DetailsView(item: item)) {
                                        FilmSerieItemView(item: item)
                            }
                        }
                    }
                case .error(let message):
                    VStack(spacing: 10) {
                        Text("Une erreur est survenue")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Séries")
            .searchable(text: $searchText, prompt: "Rechercher une série...")
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
