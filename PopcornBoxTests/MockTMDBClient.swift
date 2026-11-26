import Foundation
@testable import PopcornBox

/// Faux client TMDB : aucun appel réseau, réponses contrôlées par les tests.
final class MockTMDBClient: TMDBProviding {
    enum MockError: LocalizedError {
        case network

        var errorDescription: String? { "Erreur réseau simulée" }
    }

    var movies: [FilmSerieItem] = []
    var series: [FilmSerieItem] = []
    var error: Error?
    /// Casting personnalisé, indexé par identifiant d'œuvre.
    var castByID: [Int: [Cast]] = [:]
    /// Force un casting vide pour tester la dégradation gracieuse.
    var forceEmptyCast = false

    private(set) var suggestCalls: [MediaType] = []
    private(set) var searchQueries: [String] = []
    private(set) var castFetchCalls: [Int] = []

    @MainActor
    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
        suggestCalls.append(mediaType)
        if let error { throw error }
        return mediaType == .movie ? movies : series
    }

    @MainActor
    func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem] {
        searchQueries.append(query)
        if let error { throw error }
        return mediaType == .movie ? movies : series
    }

    @MainActor
    func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast] {
        castFetchCalls.append(id)
        if let error { throw error }
        if forceEmptyCast { return [] }
        return castByID[id] ?? makeDefaultCast(for: id)
    }
}

// MARK: - Fixtures

@MainActor
func makeCast(id: Int, name: String, character: String) -> Cast {
    Cast(id: id, name: name, character: character, profilePath: "/portrait/\(id).jpg")
}

@MainActor
func makeDefaultCast(for id: Int) -> [Cast] {
    [
        makeCast(id: id * 10 + 1, name: "Acteur \(id) A", character: "Rôle \(id) A"),
        makeCast(id: id * 10 + 2, name: "Acteur \(id) B", character: "Rôle \(id) B")
    ]
}

@MainActor
func makeItem(id: Int, title: String, kind: MediaType) -> FilmSerieItem {
    let genreIDs = [28, 35, 18, 878, 53, 12]
    return FilmSerieItem(
        id: id,
        kind: kind,
        title: title,
        snippet: "Synopsis de \(title)",
        smallPosterURL: URL(string: "https://example.com/small/\(id).jpg"),
        largePosterURL: URL(string: "https://example.com/poster/\(id).jpg"),
        url: URL(string: "https://www.themoviedb.org/\(kind == .movie ? "movie" : "tv")/\(id)"),
        backdropURL: URL(string: "https://example.com/backdrop/\(id).jpg"),
        releaseYear: 2018 + (id % 8),
        genreIDs: [genreIDs[id % genreIDs.count]],
        rating: 6.1 + Double(id % 8) * 0.4
    )
}

@MainActor
func makeCatalog(movies: Int, series: Int) -> ([FilmSerieItem], [FilmSerieItem]) {
    let movieItems = (1...movies).map { makeItem(id: $0, title: "Film \($0)", kind: .movie) }
    let seriesItems = (1...series).map { makeItem(id: 100 + $0, title: "Série \($0)", kind: .series) }
    return (movieItems, seriesItems)
}

@MainActor
func makeSources(from items: [FilmSerieItem]) -> [QuizSource] {
    items.map { QuizSource(item: $0, cast: makeDefaultCast(for: $0.id)) }
}
