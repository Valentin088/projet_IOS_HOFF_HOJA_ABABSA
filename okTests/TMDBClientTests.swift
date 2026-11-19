import XCTest
@testable import ok

@MainActor
final class TMDBClientTests: XCTestCase {

    private func makeClient(
        _ mock: MockDataTask,
        baseURL: String = "https://api.themoviedb.org/3"
    ) -> TMDBClient {
        TMDBClient(baseURL: baseURL, bearerToken: "test-token", dataTask: mock.handle)
    }

    // MARK: - Recherche

    func testSearchEncodesReservedCharactersInQuery() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.movieList)]
        let client = makeClient(mock)

        _ = try await client.search(mediaType: .movie, query: "Spider-Man & Venom?")

        let url = try XCTUnwrap(mock.lastURL)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/3/search/movie")
        XCTAssertEqual(components.queryItems?.count, 3, "Un & non encodé créerait un paramètre supplémentaire")
        let queryItem = try XCTUnwrap(components.queryItems?.first { $0.name == "query" })
        XCTAssertEqual(queryItem.value, "Spider-Man & Venom?")
    }

    func testSearchTrimsQueryAndUsesFrenchLocale() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.movieList)]
        let client = makeClient(mock)

        _ = try await client.search(mediaType: .series, query: "  Breaking Bad  ")

        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(mock.lastURL), resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/3/search/tv")
        XCTAssertEqual(components.queryItems?.first { $0.name == "query" }?.value, "Breaking Bad")
        XCTAssertEqual(components.queryItems?.first { $0.name == "language" }?.value, "fr-FR")
        XCTAssertEqual(components.queryItems?.first { $0.name == "page" }?.value, "1")
    }

    func testEmptyQueryDoesNotCallNetwork() async throws {
        let mock = MockDataTask()
        let client = makeClient(mock)

        let result = try await client.search(mediaType: .movie, query: "   ")

        XCTAssertTrue(result.isEmpty)
        XCTAssertTrue(mock.requests.isEmpty)
    }

    // MARK: - Suggestions

    func testSuggestUsesCorrectPopularEndpoints() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.movieList), .init(Fixtures.seriesList)]
        let client = makeClient(mock)

        _ = try await client.suggest(mediaType: .movie)
        _ = try await client.suggest(mediaType: .series)

        XCTAssertEqual(mock.requests.count, 2)
        XCTAssertEqual(mock.requests[0].url?.path, "/3/movie/popular")
        XCTAssertEqual(mock.requests[1].url?.path, "/3/tv/popular")
    }

    func testRequestContainsAuthenticationAndIsAGetWithTimeout() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.movieList)]
        let client = makeClient(mock)

        _ = try await client.suggest(mediaType: .movie)

        let request = try XCTUnwrap(mock.requests.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.timeoutInterval, 10)
        XCTAssertEqual(request.value(forHTTPHeaderField: "accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    // MARK: - Erreurs réseau et HTTP

    func testHTTPErrorStatusesThrowUserFriendlyErrors() async throws {
        for (status, expected) in [
            (401, TMDBError.httpStatus(401)),
            (429, TMDBError.httpStatus(429)),
            (503, TMDBError.httpStatus(503))
        ] {
            let mock = MockDataTask()
            mock.replies = [.init(Fixtures.serverError, statusCode: status)]
            let client = makeClient(mock)

            do {
                _ = try await client.suggest(mediaType: .movie)
                XCTFail("Le statut \(status) aurait dû lever une erreur")
            } catch let error as TMDBError {
                XCTAssertEqual(error, expected)
                XCTAssertFalse(error.localizedDescription.isEmpty)
            }
        }
    }

    func testErrorResponseBodyIsNotMistakenForAValidList() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.serverError, statusCode: 500)]
        let client = makeClient(mock)

        do {
            let items = try await client.suggest(mediaType: .movie)
            XCTFail("On ne doit pas renvoyer \(items.count) éléments sur une erreur 500")
        } catch let error as TMDBError {
            XCTAssertEqual(error, .httpStatus(500))
        }
    }

    func testMalformedJSONThrowsDecodingError() async throws {
        let mock = MockDataTask()
        mock.replies = [.init("{ this is not json }")]
        let client = makeClient(mock)

        do {
            _ = try await client.suggest(mediaType: .movie)
            XCTFail("Un JSON invalide doit lever une erreur")
        } catch let error as TMDBError {
            XCTAssertEqual(error, .decoding)
        }
    }

    func testInvalidBaseURLThrowsInsteadOfCrashing() async throws {
        let mock = MockDataTask()
        let client = makeClient(mock, baseURL: "pas une url valide")

        do {
            _ = try await client.suggest(mediaType: .movie)
            XCTFail("Une URL invalide doit lever une erreur, pas crasher")
        } catch let error as TMDBError {
            XCTAssertEqual(error, .invalidURL)
        }
    }

    func testOfflineErrorHasAReadableMessage() async throws {
        let mock = MockDataTask()
        mock.error = URLError(.notConnectedToInternet)
        let client = makeClient(mock)

        do {
            _ = try await client.suggest(mediaType: .movie)
            XCTFail("L'erreur réseau doit être propagée")
        } catch {
            XCTAssertEqual(
                TMDBError.message(for: error),
                "Aucune connexion Internet. Vérifiez le réseau et réessayez."
            )
        }
    }

    // MARK: - Distribution

    func testSuggestMapsAPIFieldsToUnifiedItems() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.movieList), .init(Fixtures.seriesList)]
        let client = makeClient(mock)

        let movies = try await client.suggest(mediaType: .movie)
        let series = try await client.suggest(mediaType: .series)

        XCTAssertEqual(movies.count, 2)
        XCTAssertEqual(movies.first?.id, 101)
        XCTAssertEqual(movies.first?.kind, .movie)
        XCTAssertEqual(movies.first?.title, "Film A")
        XCTAssertEqual(movies.first?.smallPosterURL?.absoluteString, "https://image.tmdb.org/t/p/w154/a.jpg")
        XCTAssertEqual(movies.first?.url?.absoluteString, "https://www.themoviedb.org/movie/101")
        XCTAssertNil(movies.last?.smallPosterURL)
        XCTAssertEqual(series.first?.kind, .series)
        XCTAssertEqual(series.first?.url?.absoluteString, "https://www.themoviedb.org/tv/201")
    }

    func testCastToleratesNullCharacterAndMissingPhoto() async throws {
        let mock = MockDataTask()
        mock.replies = [.init(Fixtures.credits)]
        let client = makeClient(mock)

        let cast = try await client.fetchCast(mediaType: .movie, id: 101)

        XCTAssertEqual(mock.lastURL?.path, "/3/movie/101/credits")
        XCTAssertEqual(cast.count, 2)
        XCTAssertEqual(cast.first?.character, "Héros")
        XCTAssertEqual(cast.last?.character, "", "Un personnage null ne doit pas casser tout le casting")
        XCTAssertNil(cast.last?.profileURL)
    }

    func testInvalidIdentifierDoesNotRequestTheAPI() async throws {
        let mock = MockDataTask()
        let client = makeClient(mock)

        do {
            _ = try await client.fetchCast(mediaType: .series, id: 0)
            XCTFail("Un identifiant invalide doit être rejeté")
        } catch let error as TMDBError {
            XCTAssertEqual(error, .invalidIdentifier)
            XCTAssertTrue(mock.requests.isEmpty)
        }
    }
}
