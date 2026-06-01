import SwiftUI

struct DetailsView: View {
    let item: FilmSerieItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(item.kindLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let snippet = item.snippet, !snippet.isEmpty {
                    Text(snippet)
                        .font(.body)
                }

                if let url = item.url {
                    Link("Ouvrir le résultat", destination: url)
                        .buttonStyle(.borderedProminent)
                } else {
                    Text("Aucun lien disponible")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Détail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DetailsView(item: FilmSerieItem(kind: .movie, title: "Exemple", snippet: "Snippet", url: URL(string: "https://example.com")))
    }
}

