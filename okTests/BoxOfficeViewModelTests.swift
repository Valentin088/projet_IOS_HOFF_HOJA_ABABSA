import XCTest
@testable import ok

@MainActor
final class BoxOfficeViewModelTests: XCTestCase {

    // MARK: - Chargement initial

    func testLoadPublishesLoadingThenLoadedWithItems() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .success([makeItem(id: 1), makeItem(id: 2)])
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        var publishedStates: [BoxOfficeViewModel.State] = []
        let subscription = viewModel.$state.sink { publishedStates.append($0) }

        await viewModel.load()
        withExtendedLifetime(subscription) {}

        XCTAssertEqual(publishedStates, [.idle, .loading, .loaded])
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.items.map(\.id), [1, 2])
        XCTAssertEqual(stub.calls, [.suggest(.movie)])
    }

    func testEmptyAPIResultIsALoadedStateWithNoItems() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .success([])
        let viewModel = BoxOfficeViewModel(mediaType: .series, client: stub)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded, "La vue doit pouvoir afficher « Aucune série trouvée »")
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testAlreadyLoadedSuggestionsAreNotFetchedAgain() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .success([makeItem(id: 1)])
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        await viewModel.load()
        await viewModel.load()

        XCTAssertEqual(stub.calls.count, 1)
    }

    // MARK: - Recherche

    func testSearchReplacesSuggestionsWithResults() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .success([makeItem(id: 1)])
        stub.searchResult = .success([makeItem(id: 9, title: "Matrix")])
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        await viewModel.load()
        await viewModel.load(query: "Matrix", force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.items.map(\.id), [9])
        XCTAssertEqual(stub.searchQueries, ["Matrix"])
    }

    func testWhitespaceOnlyQueryFallsBackToSuggestions() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .success([makeItem(id: 4)])
        let viewModel = BoxOfficeViewModel(mediaType: .series, client: stub)

        await viewModel.load(query: "   ", force: true)

        XCTAssertEqual(stub.calls, [.suggest(.series)])
        XCTAssertEqual(viewModel.items.map(\.id), [4])
    }

    func testSearchTrimsTheQueryBeforeCallingTheClient() async {
        let stub = StubTMDBClient()
        stub.searchResult = .success([])
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        await viewModel.load(query: "  Dune  ", force: true)

        XCTAssertEqual(stub.searchQueries, ["Dune"])
    }

    func testEmptySearchResultsStillShowTheEmptyState() async {
        let stub = StubTMDBClient()
        stub.searchResult = .success([])
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        await viewModel.load(query: "inconnu", force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    // MARK: - Erreurs et reprise

    func testOfflineFailureShowsAFriendlyMessage() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .failure(URLError(.notConnectedToInternet))
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .error("Aucune connexion Internet. Vérifiez le réseau et réessayez."))
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testHTTPFailureShowsAReadableMessage() async {
        let stub = StubTMDBClient()
        stub.searchResult = .failure(TMDBError.httpStatus(429))
        let viewModel = BoxOfficeViewModel(mediaType: .series, client: stub)

        await viewModel.load(query: "test", force: true)

        XCTAssertEqual(viewModel.state, .error("Trop de recherches simultanées. Réessayez dans un instant."))
    }

    func testForceReloadAfterAnErrorRecovers() async {
        let stub = StubTMDBClient()
        stub.suggestResult = .failure(TMDBError.httpStatus(500))
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .error("Le catalogue est momentanément indisponible."))

        stub.suggestResult = .success([makeItem(id: 7)])
        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.items.map(\.id), [7])
    }

    // MARK: - Concurrence

    func testOutOfOrderResponseDoesNotOverwriteTheLatestSearch() async {
        let stub = StubTMDBClient()
        stub.holdSearch = true
        stub.searchResult = .success([makeItem(id: 99, title: "Nouveau")])
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        let oldRequest = Task { await viewModel.load(query: "ancien", force: true) }
        await waitUntil { stub.searchQueries.count == 1 }

        stub.holdSearch = false
        await viewModel.load(query: "nouveau", force: true)
        XCTAssertEqual(viewModel.items.map(\.id), [99])

        stub.releaseSearch(.success([makeItem(id: 1, title: "Ancien")]))
        await oldRequest.value

        XCTAssertEqual(viewModel.items.map(\.id), [99], "La réponse ancienne ne doit pas remplacer la nouvelle")
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testCancelledSearchDoesNotDisplayAnError() async {
        let stub = StubTMDBClient()
        stub.holdSearch = true
        let viewModel = BoxOfficeViewModel(mediaType: .movie, client: stub)

        let request = Task { await viewModel.load(query: "annulé", force: true) }
        await waitUntil { stub.searchQueries.count == 1 }

        request.cancel()
        stub.releaseSearch(.failure(CancellationError()))
        await request.value

        XCTAssertNotEqual(viewModel.state, .error("The operation couldn’t be completed. (CancellationError error 1.)"))
        XCTAssertFalse(viewModel.state.isError, "Une frappe rapide ne doit pas afficher d'erreur à l'utilisateur")
    }
}

private extension BoxOfficeViewModel.State {
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
