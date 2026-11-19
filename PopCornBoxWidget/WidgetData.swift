import Foundation

// MARK: - Modèle affiché par le widget

struct WidgetMediaItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let posterData: Data?
    let url: URL?

    /// Données d'aperçu utilisées par la vue placeholder (aucun réseau nécessaire).
    static func samples(for mediaType: WidgetMediaType) -> [WidgetMediaItem] {
        let titles = mediaType == .movie
            ? ["Dune : Part Two", "Oppenheimer", "Barbie", "Poor Things", "The Batman", "Spider-Man : Across"]
            : ["The Last of Us", "Breaking Bad", "Stranger Things", "Succession", "The Bear", "Arcane"]

        return titles.enumerated().map { index, title in
            WidgetMediaItem(
                id: index,
                title: title,
                subtitle: mediaType == .movie ? "Film populaire" : "Série populaire",
                posterData: nil,
                url: nil
            )
        }
    }
}

// MARK: - Décodage TMDB

private struct TMDBResponse<T: Decodable>: Decodable {
    let results: [T]
}

private struct TMDBMedia: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
    }
}

// MARK: - Client réseau dédié au widget

/// Le widget est un processus séparé : il possède sa propre couche réseau légère.
/// Les affiches sont téléchargées ici et transmises dans la timeline sous forme de `Data`,
/// ce qui garantit un rendu fiable lors des snapshots du widget.
struct WidgetTMDBClient {
    static let shared = WidgetTMDBClient()

    private let bearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxMWI2MTg5Y2NhMjk4YTNiOTU4YzJjODA0ZmI5NDI5YSIsIm5iZiI6MTc4MDMwNTcxOC41MTYsInN1YiI6IjZhMWQ0ZjM2MzA0N2YyNDcyZTRhZDJjNCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.YjG-DYoizz1MCUCI2fQFbkdlK_dBoTGtKu4yHrcXpKU"

    func popular(mediaType: WidgetMediaType, limit: Int) async throws -> [WidgetMediaItem] {
        let endpoint = mediaType == .movie ? "movie/popular" : "tv/popular"
        guard let url = URL(string: "https://api.themoviedb.org/3/\(endpoint)?language=fr-FR&page=1") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TMDBResponse<TMDBMedia>.self, from: data)
        let top = Array(response.results.prefix(limit))

        return await withTaskGroup(of: (Int, WidgetMediaItem).self) { group in
            for (index, media) in top.enumerated() {
                group.addTask {
                    let item = WidgetMediaItem(
                        id: media.id,
                        title: media.title ?? media.name ?? "Sans titre",
                        subtitle: mediaType == .movie ? "Film populaire" : "Série populaire",
                        posterData: await Self.posterData(for: media.posterPath),
                        url: URL(string: "https://www.themoviedb.org/\(mediaType == .movie ? "movie" : "tv")/\(media.id)")
                    )
                    return (index, item)
                }
            }

            var indexed: [(Int, WidgetMediaItem)] = []
            for await result in group {
                indexed.append(result)
            }
            return indexed.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    private static func posterData(for path: String?) async -> Data? {
        guard let path, let url = URL(string: "https://image.tmdb.org/t/p/w342\(path)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            return nil
        }
        return data
    }
}
