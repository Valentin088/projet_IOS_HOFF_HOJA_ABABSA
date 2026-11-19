import SwiftUI

struct MoviesView: View {
    @StateObject private var viewModel = BoxOfficeViewModel(mediaType: .movie)
    @State private var searchText = ""

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Chargement des films...")
            case .loaded:
                if viewModel.items.isEmpty {
                    Text("Aucun film trouvé")
                        .foregroundStyle(.secondary)
                } else {
                    List(viewModel.items) { item in
                        NavigationLink {
                            DetailsView(item: item)
                        } label: {
                            FilmSerieItemView(item: item)
                        }
                    }
                    .listStyle(.carousel)
                }
            case .error(let message):
                VStack(spacing: 8) {
                    Text("Une erreur est survenue")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding()
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
                // Anti-rebond : on n'interroge l'API qu'après 0,5 s sans saisie.
                try await Task.sleep(nanoseconds: 500_000_000)
                await viewModel.load(query: searchText, force: true)
            } catch {
                // L'utilisateur a continué à taper : la requête est annulée.
            }
        }
    }
}

#Preview {
    NavigationStack {
        MoviesView()
    }
}
