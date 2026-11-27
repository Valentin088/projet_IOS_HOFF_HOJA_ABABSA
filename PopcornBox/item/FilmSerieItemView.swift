import SwiftUI

struct FilmSerieItemView: View {
    let item: FilmSerieItem
    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil

    var id: Int { item.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                if let posterURL = item.smallPosterURL {
                    AsyncImage(url: posterURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 44, height: 66)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 66)
                                .clipped()
                                .cornerRadius(6)
                        case .failure:
                            Image(systemName: item.kind == .movie ? "film" : "tv")
                                .frame(width: 44, height: 66)
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: item.kind == .movie ? "film" : "tv")
                        .frame(width: 44, height: 66)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("item.title")

                    if let snippet = item.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                if let onToggleFavorite {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .secondary)
                            .font(.title3)
                            .padding(6)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("item.favorite.\(item.id)")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("item.row.\(item.id)")
        .accessibilityLabel(Text(item.title))
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
                    url: URL(string: "https://www.themoviedb.org/movie/0"),
                    backdropURL: nil,
                    releaseYear: 2024,
                    genreIDs: [28],
                    rating: 7.5
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
                    url: URL(string: "https://www.themoviedb.org/tv/0"),
                    backdropURL: nil,
                    releaseYear: 2023,
                    genreIDs: [18],
                    rating: 8.1
                ),
                isFavorite: true
            ) {
                print("Toggle favori")
            }
        }
    }
}
