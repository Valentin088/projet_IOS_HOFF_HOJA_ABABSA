import SwiftUI

struct FilmSerieItemView: View {
    let item: FilmSerieItem

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let posterURL = item.smallPosterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    case .failure:
                        posterPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 40, height: 60)
            } else {
                posterPlaceholder
                    .frame(width: 40, height: 60)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let snippet = item.snippet, !snippet.isEmpty {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var posterPlaceholder: some View {
        Image(systemName: item.kind == .movie ? "film" : "tv")
            .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        List {
            FilmSerieItemView(
                item: FilmSerieItem(
                    id: 1,
                    kind: .movie,
                    title: "Exemple film",
                    snippet: "Un aperçu…",
                    smallPosterURL: nil,
                    largePosterURL: nil,
                    url: URL(string: "https://www.themoviedb.org/movie/0")
                )
            )
            FilmSerieItemView(
                item: FilmSerieItem(
                    id: 2,
                    kind: .series,
                    title: "Exemple série",
                    snippet: "Un aperçu…",
                    smallPosterURL: nil,
                    largePosterURL: nil,
                    url: URL(string: "https://www.themoviedb.org/tv/0")
                )
            )
        }
    }
}
