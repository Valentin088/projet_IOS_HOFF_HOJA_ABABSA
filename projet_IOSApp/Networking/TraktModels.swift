import Foundation

// MARK: - Trakt models (minimal pour alimenter FilmSerieItem)

struct TraktSearchResponse: Decodable {
    struct SearchResult: Decodable {
        let title: String?
        let year: Int?

        // Trakt peut renvoyer "movie" ou "show" selon l’endpoint
        let type: String?

        let ids: Ids?

        struct Ids: Decodable {
            let trakt: Int?
            let imdb: String?
            let tmdb: Int?
        }
    }

    let results: [SearchResult]

    // Certains endpoints renvoient directement un tableau ; on tolère en pratique
    // côté client (on évite ici d’alourdir avec des wrappers multiples).
}

/// Wrapper flexible : si l’API renvoie un tableau direct
struct TraktArrayResponse<T: Decodable>: Decodable {
    let items: [T]
}

