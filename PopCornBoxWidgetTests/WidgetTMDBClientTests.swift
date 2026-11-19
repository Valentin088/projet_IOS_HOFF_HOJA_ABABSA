import XCTest

final class WidgetTMDBClientTests: XCTestCase {
    private var session: URLSession!
    private var client: WidgetTMDBClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.box = MockResponseBox()
        URLProtocol.registerClass(MockURLProtocol.self)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        client = WidgetTMDBClient(session: session, token: "test-token")
    }

    override func tearDown() {
        MockURLProtocol.box = nil
        URLProtocol.unregisterClass(MockURLProtocol.self)
        session = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Requête

    func testPopularMoviesUsesFrenchEndpointAndAuthHeaders() async throws {
        let captured = CapturedRequest()
        MockURLProtocol.box?.handler = { request in
            captured.request = request
            return (Self.response(for: request), try Self.resultsJSON([]))
        }

        _ = try await client.popular(mediaType: .movie, limit: 3)

        let request = try XCTUnwrap(captured.request)
        let url = try XCTUnwrap(request.url)
        XCTAssertEqual(url.path, "/3/movie/popular")
        XCTAssertEqual(Self.query("language", in: url), "fr-FR")
        XCTAssertEqual(Self.query("page", in: url), "1")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.timeoutInterval, 10)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "accept"), "application/json")
    }

    func testPopularSeriesUsesTvEndpoint() async throws {
        let captured = CapturedRequest()
        MockURLProtocol.box?.handler = { request in
            captured.request = request
            return (Self.response(for: request), try Self.resultsJSON([]))
        }

        _ = try await client.popular(mediaType: .series, limit: 3)

        XCTAssertEqual(try XCTUnwrap(captured.request?.url).path, "/3/tv/popular")
    }

    // MARK: - Décodage et classement

    func testResultsKeepRankOrderAndMapFields() async throws {
        MockURLProtocol.box?.handler = { request in
            (
                Self.response(for: request),
                try Self.resultsJSON([
                    Self.media(id: 11, title: "Premier"),
                    Self.media(id: 22, title: "Deuxième"),
                    Self.media(id: 33, title: "Troisième")
                ])
            )
        }

        let items = try await client.popular(mediaType: .movie, limit: 6)

        XCTAssertEqual(items.map(\.id), [11, 22, 33])
        XCTAssertEqual(items.map(\.title), ["Premier", "Deuxième", "Troisième"])
        XCTAssertEqual(items.map(\.subtitle), Array(repeating: "Film populaire", count: 3))
        XCTAssertEqual(items.first?.url?.absoluteString, "https://www.themoviedb.org/movie/11")
        XCTAssertTrue(items.allSatisfy { $0.posterData == nil })
    }

    func testSeriesDetailLinkPointsToTvPage() async throws {
        MockURLProtocol.box?.handler = { request in
            (Self.response(for: request), try Self.resultsJSON([Self.media(id: 77, title: "Série")]))
        }

        let items = try await client.popular(mediaType: .series, limit: 1)

        XCTAssertEqual(items.first?.url?.absoluteString, "https://www.themoviedb.org/tv/77")
        XCTAssertEqual(items.first?.subtitle, "Série populaire")
    }

    func testLimitCapsNumberOfItems() async throws {
        MockURLProtocol.box?.handler = { request in
            let results = (1...8).map { Self.media(id: $0, title: "Film \($0)") }
            return (Self.response(for: request), try Self.resultsJSON(results))
        }

        let items = try await client.popular(mediaType: .movie, limit: 3)

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.map(\.id), [1, 2, 3])
    }

    func testMissingTitleFallsBackToNameThenToPlaceholder() async throws {
        MockURLProtocol.box?.handler = { request in
            (
                Self.response(for: request),
                try Self.resultsJSON([
                    ["id": 1, "name": "Série titrée", "overview": "", "poster_path": NSNull()],
                    ["id": 2, "overview": "", "poster_path": NSNull()]
                ])
            )
        }

        let items = try await client.popular(mediaType: .series, limit: 5)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Série titrée")
        XCTAssertEqual(items[1].title, "Sans titre")
    }

    func testEmptyResultsReturnNoItems() async throws {
        MockURLProtocol.box?.handler = { request in
            (Self.response(for: request), try Self.resultsJSON([]))
        }

        let items = try await client.popular(mediaType: .movie, limit: 6)

        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - Affiches

    func testPosterDataIsDownloadedAndAttached() async throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        let posterURL = "https://image.tmdb.org/t/p/w342/poster.jpg"
        let capturedPosterURL = CapturedString()

        MockURLProtocol.box?.handler = { request in
            if request.url?.host == "api.themoviedb.org" {
                let results: [[String: Any]] = [
                    ["id": 7, "title": "Avec affiche", "overview": "", "poster_path": "/poster.jpg"]
                ]
                return (Self.response(for: request), try Self.resultsJSON(results))
            }
            capturedPosterURL.value = request.url?.absoluteString
            return (Self.response(for: request), imageData)
        }

        let items = try await client.popular(mediaType: .movie, limit: 1)

        XCTAssertEqual(capturedPosterURL.value, posterURL)
        XCTAssertEqual(items.first?.posterData, imageData)
        XCTAssertEqual(items.first?.title, "Avec affiche")
    }

    func testFailedPosterDownloadDoesNotDropTheItem() async throws {
        MockURLProtocol.box?.handler = { request in
            if request.url?.host == "api.themoviedb.org" {
                let results: [[String: Any]] = [
                    ["id": 7, "title": "Sans affiche", "overview": "", "poster_path": "/absent.jpg"]
                ]
                return (Self.response(for: request), try Self.resultsJSON(results))
            }
            return (Self.response(for: request, statusCode: 500), Data())
        }

        let items = try await client.popular(mediaType: .movie, limit: 1)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "Sans affiche")
        XCTAssertNil(items.first?.posterData)
    }

    // MARK: - Erreurs réseau

    func testMalformedJSONThrows() async throws {
        MockURLProtocol.box?.handler = { request in
            (Self.response(for: request), Data("{ ce n'est pas du JSON".utf8))
        }

        do {
            _ = try await client.popular(mediaType: .movie, limit: 1)
            XCTFail("Une réponse invalide doit lever une erreur.")
        } catch {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testHTTPErrorThrows() async throws {
        MockURLProtocol.box?.handler = { request in
            (Self.response(for: request, statusCode: 503), Data("unavailable".utf8))
        }

        do {
            _ = try await client.popular(mediaType: .movie, limit: 1)
            XCTFail("Une erreur HTTP doit lever une erreur de décodage.")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testNetworkFailureThrows() async throws {
        MockURLProtocol.box?.handler = { _ in
            throw NSError(domain: "test.offline", code: -1009, userInfo: nil)
        }

        do {
            _ = try await client.popular(mediaType: .series, limit: 1)
            XCTFail("Une panne réseau doit être propagée au provider.")
        } catch {
            XCTAssertEqual((error as NSError).domain, "test.offline")
        }
    }

    // MARK: - URLs

    func testAPIHelpersBuildExpectedURLs() {
        XCTAssertNil(WidgetAPI.posterURL(path: nil))
        XCTAssertEqual(
            WidgetAPI.posterURL(path: "/x.jpg")?.absoluteString,
            "https://image.tmdb.org/t/p/w342/x.jpg"
        )
        XCTAssertEqual(
            WidgetAPI.detailURL(mediaType: .movie, id: 5)?.absoluteString,
            "https://www.themoviedb.org/movie/5"
        )
        XCTAssertEqual(
            WidgetAPI.detailURL(mediaType: .series, id: 9)?.absoluteString,
            "https://www.themoviedb.org/tv/9"
        )
        XCTAssertEqual(
            WidgetAPI.popularURL(for: .movie)?.host,
            "api.themoviedb.org"
        )
    }

    // MARK: - Outils

    private final class CapturedRequest {
        var request: URLRequest?
    }

    private final class CapturedString {
        var value: String?
    }

    private static func response(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
    }

    private static func resultsJSON(_ results: [[String: Any]]) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["results": results])
    }

    private static func media(id: Int, title: String) -> [String: Any] {
        ["id": id, "title": title, "overview": "Synopsis", "poster_path": NSNull()]
    }

    private static func query(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
