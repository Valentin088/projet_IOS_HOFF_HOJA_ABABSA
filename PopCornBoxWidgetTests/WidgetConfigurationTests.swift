import XCTest

final class WidgetConfigurationTests: XCTestCase {
    func testMediaTypeRawValuesAreStableForSavedConfiguration() {
        XCTAssertEqual(WidgetMediaType.movie.rawValue, "movie")
        XCTAssertEqual(WidgetMediaType.series.rawValue, "series")
        XCTAssertEqual(WidgetMediaType.allCases.count, 2)
    }

    func testDefaultConfigurationIsMovies() {
        let intent = ConfigurationAppIntent()

        XCTAssertEqual(intent.mediaType, .movie)
    }

    func testConfigurationCanSwitchToSeries() {
        var intent = ConfigurationAppIntent()
        intent.mediaType = .series

        XCTAssertEqual(intent.mediaType, .series)
    }

    func testMediaTypeDrivesIconsAndHeadings() {
        XCTAssertEqual(WidgetMediaType.movie.symbolName, "film.fill")
        XCTAssertEqual(WidgetMediaType.series.symbolName, "tv.fill")
        XCTAssertEqual(WidgetMediaType.movie.headline, "Top films")
        XCTAssertEqual(WidgetMediaType.series.headline, "Top séries")
        XCTAssertEqual(WidgetMediaType.movie.longHeadline, "Films populaires")
        XCTAssertEqual(WidgetMediaType.series.longHeadline, "Séries populaires")
    }

    func testMediaTypeDrivesItemSubtitle() {
        XCTAssertEqual(WidgetMediaType.movie.subtitle, "Film populaire")
        XCTAssertEqual(WidgetMediaType.series.subtitle, "Série populaire")
    }

    func testDisplayRepresentationsExistForBothChoices() {
        XCTAssertFalse(WidgetMediaType.caseDisplayRepresentations[.movie] == nil)
        XCTAssertFalse(WidgetMediaType.caseDisplayRepresentations[.series] == nil)
    }
}
