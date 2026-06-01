import Foundation

final class DuckDuckGoClient {
    enum ClientError: Error {
        case badURL
        case badResponse
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Recherche DuckDuckGo via le endpoint JSON.
    func search(query: String) async throws -> [FilmSerieItem] {
        let endpoint = "https://api.duckduckgo.com/"
        guard var components = URLComponents(string: endpoint) else {
            throw ClientError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "no_redirect", value: "1"),
            URLQueryItem(name: "no_html", value: "1")
        ]

        guard let url = components.url else {
            throw ClientError.badURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ClientError.badResponse
        }

        let decoded = try JSONDecoder().decode(DuckDuckGoSearchResponse.self, from: data)

        // On a parfois une structure imbriquée.
        var results: [FilmSerieItem] = []
        let related = decoded.RelatedTopics ?? []

        func appendTopic(_ topic: DuckDuckGoSearchResponse.RelatedTopic, mediaType: MediaType) {
            if let firstURL = topic.FirstURL, let url = URL(string: firstURL) {
                let title = topic.Text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? url.absoluteString
                results.append(FilmSerieItem(kind: mediaType, title: title, snippet: topic.Text, url: url))
            }
            if let topics = topic.Topics {
                for t in topics {
                    appendTopic(t, mediaType: mediaType)
                }
            }
        }

        // Déterminer type depuis le query (simple).
        let mediaType: MediaType = query.lowercased().contains("series") ? .series : .movie

        for t in related {
            appendTopic(t, mediaType: mediaType)
        }

        // On limite
        return Array(results.prefix(25))
    }
}

