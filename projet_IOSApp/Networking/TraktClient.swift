import Foundation

final class TraktClient {
    enum ClientError: Error {
        case badURL
        case badResponse
        case missingCredentials
    }

    private let session: URLSession

    // TODO: sécuriser via Info.plist ou xcconfig.
    private let clientID = "e75ea9b3ffc30b2c350b2ef4d16cfc95f38f7452e4d1b5e64c680de2464320fa"
    private let clientSecret = "c4f97ab3d4b6a85fb7abe5a5c93999f647cf1f264df2ad885f30838a2fd3364b"

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Suggestion “box office” approximée via recherche Trakt.
    /// On retourne un tableau limité, adapté à l’UI.
    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
        // Trakt propose /search (multi-types). On limite en choisissant un type cible.
        // Pour "séries", on cible des "show".
        // Pour "films", on cible des "movie".
        let query: String
        let typeFilter: String

        switch mediaType {
        case .movie:
            query = "box office"
            typeFilter = "movie"
        case .series:
            query = "box office"
            typeFilter = "show"
        }

        // Endpoint : https://api.trakt.tv/search?query=...&type=...
        // Selon versions, "type" attend movie/show/person/etc.
        let endpoint = "https://api.trakt.tv/search"

        guard var components = URLComponents(string: endpoint) else {
            throw ClientError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type", value: typeFilter)
        ]

        guard let url = components.url else {
            throw ClientError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(clientID, forHTTPHeaderField: "trakt-api-key")
        // Trakt n’utilise pas toujours client-secret en header sur /search.
        // On l’ajoute pour compat.
        request.setValue(clientSecret, forHTTPHeaderField: "trakt-api-secret")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ClientError.badResponse
        }

        // /search renvoie souvent un tableau d’objets.
        // On décode comme tableau de SearchResult-like.
        let decoded = try JSONDecoder().decode([TraktSearchResultPayload].self, from: data)

        let items = decoded.prefix(25).map { payload in
            let title = payload.title ?? "Sans titre"
            // Map Trakt types -> MediaType (même si on a filtré)
            let kind: MediaType = (payload.type?.lowercased() == "show") ? .series : .movie
            let url: URL? = nil
            return FilmSerieItem(kind: kind, title: title, snippet: payload.year != nil ? "\(payload.year!)" : nil, url: url)
        }

        return items
    }
}

// Payload minimal pour /search.
private struct TraktSearchResultPayload: Decodable {
    let title: String?
    let year: Int?
    let type: String?
    let ids: TraktClient.TraktIds?

    // ids est variable ; on le rend optionnel
    struct TraktIds: Decodable {
        let imdb: String?
        let tmdb: Int?
        let trakt: Int?
    }
}

