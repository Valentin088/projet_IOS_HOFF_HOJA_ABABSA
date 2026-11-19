import XCTest

final class WidgetContentTests: XCTestCase {
    func testSamplesProvideSixItemsForMovies() {
        let items = WidgetMediaItem.samples(for: .movie)

        XCTAssertEqual(items.count, 6)
        XCTAssertTrue(items.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(items.allSatisfy { $0.subtitle == "Film populaire" })
    }

    func testSamplesProvideSixItemsForSeries() {
        let items = WidgetMediaItem.samples(for: .series)

        XCTAssertEqual(items.count, 6)
        XCTAssertTrue(items.allSatisfy { $0.subtitle == "Série populaire" })
    }

    func testSampleIdentifiersAreUnique() {
        let movies = WidgetMediaItem.samples(for: .movie)
        let series = WidgetMediaItem.samples(for: .series)

        XCTAssertEqual(Set(movies.map(\.id)).count, movies.count)
        XCTAssertEqual(Set(series.map(\.id)).count, series.count)
    }

    func testSamplesNeedNoNetworkAndNoPoster() {
        let items = WidgetMediaItem.samples(for: .movie) + WidgetMediaItem.samples(for: .series)

        XCTAssertTrue(items.allSatisfy { $0.posterData == nil })
        XCTAssertTrue(items.allSatisfy { $0.url == nil })
    }

    func testEntryWithNoItemsIsMarkedAsRealContent() {
        let entry = PopularMediaEntry(
            date: Date(),
            items: [],
            mediaType: .movie,
            isPlaceholder: false
        )

        XCTAssertTrue(entry.items.isEmpty, "L'état vide doit être géré par la vue, pas considéré comme un placeholder.")
        XCTAssertFalse(entry.isPlaceholder)
    }

    func testEntryDateIsUsableForTimeline() {
        let now = Date()
        let entry = PopularMediaEntry(
            date: now,
            items: WidgetMediaItem.samples(for: .series),
            mediaType: .series,
            isPlaceholder: false
        )

        XCTAssertLessThanOrEqual(entry.date.timeIntervalSince(now), 1)
        XCTAssertEqual(entry.items.count, 6)
    }
}
