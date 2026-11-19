import XCTest

/// Faux client : permet de simuler une réponse, une panne réseau et de vérifier les paramètres envoyés.
final class MockMediaClient: WidgetMediaProviding {
    var items: [WidgetMediaItem] = []
    var error: Error?
    private(set) var calls: [(mediaType: WidgetMediaType, limit: Int)] = []

    func popular(mediaType: WidgetMediaType, limit: Int) async throws -> [WidgetMediaItem] {
        calls.append((mediaType, limit))
        if let error { throw error }
        return items
    }
}

final class PopularMediaProviderTests: XCTestCase {
    private var client: MockMediaClient!
    private var provider: PopularMediaProvider!

    override func setUp() {
        super.setUp()
        client = MockMediaClient()
        provider = PopularMediaProvider(client: client)
    }

    override func tearDown() {
        client = nil
        provider = nil
        super.tearDown()
    }

    func testEntryAsksForConfiguredMediaTypeAndFixedLimit() async {
        _ = await provider.entry(for: .series)

        XCTAssertEqual(client.calls.count, 1)
        XCTAssertEqual(client.calls.first?.mediaType, .series)
        XCTAssertEqual(client.calls.first?.limit, PopularMediaProvider.itemLimit)
    }

    func testMovieConfigurationRequestsMovies() async {
        _ = await provider.entry(for: .movie)

        XCTAssertEqual(client.calls.first?.mediaType, .movie)
    }

    func testEntryContainsFetchedItemsInOrder() async {
        client.items = [
            WidgetMediaItem(id: 1, title: "A", subtitle: "Film populaire", posterData: nil, url: nil),
            WidgetMediaItem(id: 2, title: "B", subtitle: "Film populaire", posterData: nil, url: nil)
        ]

        let entry = await provider.entry(for: .movie)

        XCTAssertEqual(entry.items.map(\.id), [1, 2])
        XCTAssertEqual(entry.items.map(\.title), ["A", "B"])
        XCTAssertEqual(entry.mediaType, .movie)
        XCTAssertFalse(entry.isPlaceholder)
    }

    func testNetworkFailureProducesEmptyEntryWithoutThrowing() async {
        client.error = NSError(domain: "test.offline", code: -1009, userInfo: nil)

        let entry = await provider.entry(for: .series)

        XCTAssertTrue(entry.items.isEmpty, "Une panne réseau doit afficher l'état vide, pas planter.")
        XCTAssertEqual(entry.mediaType, .series)
        XCTAssertFalse(entry.isPlaceholder)
    }

    func testPlaceholderUsesSamplesAndNeverCallsNetwork() {
        let entry = PopularMediaProvider.placeholderEntry()

        XCTAssertTrue(entry.isPlaceholder)
        XCTAssertEqual(entry.mediaType, .movie)
        XCTAssertEqual(entry.items.count, 6)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testNextRefreshIsThreeHoursLater() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let next = provider.nextRefreshDate(from: start)

        XCTAssertEqual(
            next.timeIntervalSince(start),
            TimeInterval(PopularMediaProvider.refreshIntervalHours * 3_600),
            accuracy: 1
        )
        XCTAssertEqual(PopularMediaProvider.refreshIntervalHours, 3)
    }

    func testItemLimitCoversLargestWidgetLayout() {
        XCTAssertEqual(PopularMediaProvider.itemLimit, 6)
    }
}
