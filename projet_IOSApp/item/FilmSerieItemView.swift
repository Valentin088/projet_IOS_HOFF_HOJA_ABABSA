import SwiftUI

struct FilmSerieItemView: View {
    let item: FilmSerieItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let snippet = item.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        List {
            FilmSerieItemView(
                item: FilmSerieItem(
                    kind: .movie,
                    title: "Exemple film",
                    snippet: "Un aperçu…",
                    url: URL(string: "https://www.themoviedb.org/movie/0")
                )
            )
            FilmSerieItemView(
                item: FilmSerieItem(
                    kind: .series,
                    title: "Exemple série",
                    snippet: "Un aperçu…",
                    url: URL(string: "https://www.themoviedb.org/tv/0")
                )
            )
        }
    }
}


