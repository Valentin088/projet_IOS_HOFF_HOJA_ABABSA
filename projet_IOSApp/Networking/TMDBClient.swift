import Foundation

final class TMDBClient {
    enum ClientError: Error {
        case badURL
        case badResponse
    }

    // Clé demandée par l’énoncé.
    // NOTE: dans une vraie app, ne jamais hardcoder une clé en prod.
    private let apiKey = "11b6189cca298a3b958c2c804fb9429a"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
        // “Box office” approximé par Popular sur TMDB.
        // - Films: /movie/popular
        // - Séries: /tv/popular
        let (path, kind): (String, MediaType) = {
            switch mediaType {
            case .movie:
                return ("/3/movie/popular", .movie)
            case .series:
                return ("/3/tv/popular", .series)
            }
        }()

        guard let url = URL(string: "https://api.themoviedb.org\(path)?api_key=\(apiKey)&language=fr-FR&page=1") else {
            throw ClientError.badURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ClientError.badResponse
        }

        switch kind {
        case .movie:
            let decoded = try JSONDecoder().decode(TMDBPopularResponse<TMDBMovie>.self, from: data)
            return decoded.results.prefix(25).map { movie in
                let title = movie.title ?? "Sans titre"
                let snippet = movie.overview
                let url = URL(string: "https://www.themoviedb.org/movie/\(movie.id)")
                return FilmSerieItem(kind: .movie, title: title, snippet: snippet, url: url)
            }
        case .series:
            let decoded = try JSONDecoder().decode(TMDBPopularResponse<TMDBTV>.self, from: data)
            return decoded.results.prefix(25).map { tv in
                let title = tv.name ?? "Sans titre"
                let snippet = tv.overview
                let url = URL(string: "https://www.themoviedb.org/tv/\(tv.id)")
                return FilmSerieItem(kind: .series, title: title, snippet: snippet, url: url)
            }
        }
    }
}

