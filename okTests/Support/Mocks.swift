import Foundation
import XCTest
@testable import ok

// MARK: - Données de test

enum Fixtures {
    static let movieList = """
    {"results":[{"id":101,"title":"Film A","overview":"Synopsis A","poster_path":"/a.jpg"},{"id":102,"title":"Film B","overview":"","poster_path":null}]}
    """

    static let seriesList = """
    {"results":[{"id":201,"name":"Série A","overview":"Synopsis A","poster_path":"/s.jpg"}]}
    """

    static let credits = """
    {"cast":[{"id":1,"name":"Acteur A","character":"Héros","profile_path":"/p.jpg"},{"id":2,"name":"Acteur B","character":null,"profile_path":null}]}
    """

    static let serverError = """
    {"status_code":500,"status_message":"Internal error"}
    """
}

// MARK: - Réseau simulé

@MainActor
final class MockDataTask: @unchecked Sendable {
    struct Reply {
        let data: Data
        let statusCode: Int

        init(_ json: String, statusCode: Int = 200) {
            self.data = Data(json.utf8)
            self.statusCode = statusCode
        }
    }

    var replies: [Reply] = []
    var error: Error?
    private(set) var requests: [URLRequest] = []

    func handle(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if let error { throw error }

        let reply = replies.isEmpty ? Reply("{}") : replies.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: reply.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (reply.data, response)
    }

    var lastURL: URL? { requests.last?.url }
}

// MARK: - Client TMDB simulé

@MainActor
final class StubTMDBClient: TMDBClientProtocol {
    enum Call: Equatable {
        case suggest(MediaType)
        case search(MediaType, String)
        case cast(MediaType, Int)
    }

    var calls: [Call] = []
    var suggestResult: Result<[FilmSerieItem], Error> = .success([])
    var searchResult: Result<[FilmSerieItem], Error> = .success([])
    var castResult: Result<[Cast], Error> = .success([])

    /// Permet de bloquer une recherche pour simuler une réponse hors ordre ou une annulation.
    var holdSearch = false
    private var pendingSearch: CheckedContinuation<[FilmSerieItem], Error>?

    func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
        calls.append(.suggest(mediaType))
        return try suggestResult.get()
    }

    func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem] {
        calls.append(.search(mediaType, query))
        if holdSearch {
            return try await withCheckedThrowingContinuation { continuation in
                pendingSearch = continuation
            }
        }
        return try searchResult.get()
    }

    func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast] {
        calls.append(.cast(mediaType, id))
        return try castResult.get()
    }

    func releaseSearch(_ result: Result<[FilmSerieItem], Error>) {
        pendingSearch?.resume(with: result)
        pendingSearch = nil
    }

    var searchQueries: [String] {
        calls.compactMap {
            if case .search(_, let query) = $0 { return query }
            return nil
        }
    }
}

// MARK: - Utilitaire

func makeItem(id: Int, title: String = "Titre") -> FilmSerieItem {
    FilmSerieItem(
        id: id,
        kind: .movie,
        title: title,
        snippet: "Synopsis",
        smallPosterURL: nil,
        largePosterURL: nil,
        url: URL(string: "https://www.themoviedb.org/movie/\(id)")
    )
}

@MainActor
func waitUntil(_ condition: @MainActor () -> Bool, timeout: TimeInterval = 2) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline {
            XCTFail("Condition non remplie avant \(timeout)s")
            return
        }
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
}
