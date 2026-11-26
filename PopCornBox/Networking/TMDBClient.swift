import Foundation

/// Abstraction du client TMDB : permet de remplacer les appels réseau par un stub dans les tests.
protocol TMDBClientProtocol {
    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem]
    func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem]
    func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast]
}

/// Erreurs métier avec un message compréhensible par l'utilisateur final.
enum TMDBError: LocalizedError, Equatable {
    case invalidURL
    case invalidIdentifier
    case httpStatus(Int)
    case decoding
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Impossible de contacter le catalogue."
        case .invalidIdentifier:
            return "Ce contenu n'est plus disponible."
        case .httpStatus(401), .httpStatus(403):
            return "L'accès au catalogue a expiré. Réessayez plus tard."
        case .httpStatus(429):
            return "Trop de recherches simultanées. Réessayez dans un instant."
        case .httpStatus(500...599):
            return "Le catalogue est momentanément indisponible."
        case .httpStatus(let code):
            return "Une erreur est survenue (code \(code))."
        case .decoding:
            return "Les données reçues sont invalides."
        case .network(let message):
            return message
        }
    }

    /// Convertit n'importe quelle erreur réseau en message affichable.
    static func message(for error: Error) -> String {
        if let tmdbError = error as? TMDBError {
            return tmdbError.localizedDescription
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "Aucune connexion Internet. Vérifiez le réseau et réessayez."
            case .timedOut:
                return "La recherche a mis trop de temps. Réessayez."
            default:
                return "Impossible de contacter le catalogue. Réessayez."
            }
        }
        return "Une erreur est survenue. Réessayez."
    }
}

typealias TMDBDataTask = @MainActor (URLRequest) async throws -> (Data, URLResponse)

final class TMDBClient: TMDBClientProtocol {
    private let baseURL: String
    private let bearerToken: String
    private let dataTask: TMDBDataTask

    convenience init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(UITestDataTask.launchArgument) {
            self.init(
                baseURL: "https://uitest.local/3",
                bearerToken: "uitest",
                dataTask: UITestDataTask.make()
            )
            return
        }
        #endif
        self.init(
            baseURL: "https://api.themoviedb.org/3",
            bearerToken: "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxMWI2MTg5Y2NhMjk4YTNiOTU4YzJjODA0ZmI5NDI5YSIsIm5iZiI6MTc4MDMwNTcxOC41MTYsInN1YiI6IjZhMWQ0ZjM2MzA0N2YyNDcyZTRhZDJjNCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.YjG-DYoizz1MCUCI2fQFbkdlK_dBoTGtKu4yHrcXpKU",
            dataTask: { request in try await URLSession.shared.data(for: request) }
        )
    }

    init(baseURL: String, bearerToken: String, dataTask: @escaping TMDBDataTask) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.dataTask = dataTask
    }

    private func fetch<T: Decodable>(path: String, query: [URLQueryItem] = []) async throws -> T {
        guard let parsed = URLComponents(string: baseURL),
              let scheme = parsed.scheme, !scheme.isEmpty,
              parsed.host != nil else {
            throw TMDBError.invalidURL
        }
        var components = parsed
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        components.path = basePath + path
        if !query.isEmpty {
            // URLComponents encode les caractères réservés (&, ?, #, accents, ...).
            components.queryItems = query
        }
        guard let url = components.url else {
            throw TMDBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await dataTask(request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw TMDBError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw TMDBError.decoding
        }
    }

    // MARK: - Méthodes unifiées requises par le ViewModel

    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
        let commonQuery = [
            URLQueryItem(name: "language", value: "fr-FR"),
            URLQueryItem(name: "page", value: "1")
        ]

        switch mediaType {
        case .movie:
            let response: TMDBResponse<Movie> = try await fetch(
                path: "/movie/popular",
                query: commonQuery
            )
            return response.results.map(item(from:))
        case .series:
            let response: TMDBResponse<TVShow> = try await fetch(
                path: "/tv/popular",
                query: commonQuery
            )
            return response.results.map(item(from:))
        }
    }

    func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let commonQuery = [
            URLQueryItem(name: "language", value: "fr-FR"),
            URLQueryItem(name: "query", value: trimmedQuery),
            URLQueryItem(name: "page", value: "1")
        ]

        switch mediaType {
        case .movie:
            let response: TMDBResponse<Movie> = try await fetch(
                path: "/search/movie",
                query: commonQuery
            )
            return response.results.map(item(from:))
        case .series:
            let response: TMDBResponse<TVShow> = try await fetch(
                path: "/search/tv",
                query: commonQuery
            )
            return response.results.map(item(from:))
        }
    }

    func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast] {
        guard id > 0 else { throw TMDBError.invalidIdentifier }

        switch mediaType {
        case .movie:
            let response: CreditsResponse = try await fetch(path: "/movie/\(id)/credits")
            return response.cast
        case .series:
            let response: CreditsResponse = try await fetch(path: "/tv/\(id)/credits")
            return response.cast
        }
    }

    private func item(from movie: Movie) -> FilmSerieItem {
        FilmSerieItem(
            id: movie.id,
            kind: .movie,
            title: movie.title,
            snippet: movie.overview,
            smallPosterURL: movie.smallPosterURL,
            largePosterURL: movie.largePosterURL,
            url: URL(string: "https://www.themoviedb.org/movie/\(movie.id)"),
            backdropURL: movie.backdropURL,
            releaseYear: movie.releaseYear,
            genreIDs: movie.genreIDs,
            rating: movie.voteAverage
        )
    }

    private func item(from show: TVShow) -> FilmSerieItem {
        FilmSerieItem(
            id: show.id,
            kind: .series,
            title: show.name,
            snippet: show.overview,
            smallPosterURL: show.smallPosterURL,
            largePosterURL: show.largePosterURL,
            url: URL(string: "https://www.themoviedb.org/tv/\(show.id)"),
            backdropURL: show.backdropURL,
            releaseYear: show.releaseYear,
            genreIDs: show.genreIDs,
            rating: show.voteAverage
        )
    }
}
