import Foundation

// MARK: - Points d'accès TMDB (isolés pour être testables)

enum WidgetAPI {
    static let baseURL = "https://api.themoviedb.org/3"
    static let posterBaseURL = "https://image.tmdb.org/t/p/w342"
    static let tmdbBaseURL = "https://www.themoviedb.org"

    static func popularURL(for mediaType: WidgetMediaType) -> URL? {
        let endpoint = mediaType == .movie ? "movie/popular" : "tv/popular"
        return URL(string: "\(baseURL)/\(endpoint)?language=fr-FR&page=1")
    }

    static func posterURL(path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: "\(posterBaseURL)\(path)")
    }

    static func detailURL(mediaType: WidgetMediaType, id: Int) -> URL? {
        URL(string: "\(tmdbBaseURL)/\(mediaType == .movie ? "movie" : "tv")/\(id)")
    }
}

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
                subtitle: mediaType.subtitle,
                posterData: nil,
                url: nil
            )
        }
    }
}

// MARK: - Abstraction du client (permet d'injecter un faux client dans les tests)

protocol WidgetMediaProviding {
    func popular(mediaType: WidgetMediaType, limit: Int) async throws -> [WidgetMediaItem]
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
struct WidgetTMDBClient: WidgetMediaProviding {
    static let shared = WidgetTMDBClient()

    let session: URLSession
    let token: String

    init(
        session: URLSession = .shared,
        token: String = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxMWI2MTg5Y2NhMjk4YTNiOTU4YzJjODA0ZmI5NDI5YSIsIm5iZiI6MTc4MDMwNTcxOC41MTYsInN1YiI6IjZhMWQ0ZjM2MzA0N2YyNDcyZTRhZDJjNCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.YjG-DYoizz1MCUCI2fQFbkdlK_dBoTGtKu4yHrcXpKU"
    ) {
        self.session = session
        self.token = token
    }

    func popular(mediaType: WidgetMediaType, limit: Int) async throws -> [WidgetMediaItem] {
        guard let url = WidgetAPI.popularURL(for: mediaType) else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(TMDBResponse<TMDBMedia>.self, from: data)
        let top = Array(response.results.prefix(limit))
        let session = self.session

        return await withTaskGroup(of: (Int, WidgetMediaItem).self) { group in
            for (index, media) in top.enumerated() {
                group.addTask {
                    let item = WidgetMediaItem(
                        id: media.id,
                        title: media.title ?? media.name ?? "Sans titre",
                        subtitle: mediaType.subtitle,
                        posterData: await Self.posterData(from: session, path: media.posterPath),
                        url: WidgetAPI.detailURL(mediaType: mediaType, id: media.id)
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

    /// Une affiche manquante ou en échec ne doit jamais empêcher l'affichage de l'entrée.
    private static func posterData(from session: URLSession, path: String?) async -> Data? {
        guard let url = WidgetAPI.posterURL(path: path) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            return nil
        }
        return data
    }
}
