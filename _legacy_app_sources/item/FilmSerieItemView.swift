import SwiftUI

struct FilmSerieItemView: View {
    let item: FilmSerieItem

    // iOS/SwiftUI: `id` peut être utile pour List/ForEach.
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
                    id : 1,
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
                    id : 2,
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

