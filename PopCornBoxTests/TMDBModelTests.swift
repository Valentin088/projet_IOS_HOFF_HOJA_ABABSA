import XCTest
@testable import PopCornBox

@MainActor
final class TMDBModelTests: XCTestCase {

    func testMoviePosterURLsUseTheExpectedImageSizes() throws {
        let decoder = JSONDecoder()
        let withPoster = try decoder.decode(Movie.self, from: Data(#"""
        {"id":1,"title":"Film","overview":"...","poster_path":"/poster.jpg"}
        """#.utf8))
        let withoutPoster = try decoder.decode(Movie.self, from: Data(#"""
        {"id":2,"title":"Film","overview":"...","poster_path":null}
        """#.utf8))

        XCTAssertEqual(withPoster.smallPosterURL?.absoluteString, "https://image.tmdb.org/t/p/w154/poster.jpg")
        XCTAssertEqual(withPoster.largePosterURL?.absoluteString, "https://image.tmdb.org/t/p/w500/poster.jpg")
        XCTAssertNil(withoutPoster.smallPosterURL)
        XCTAssertNil(withoutPoster.largePosterURL)
    }

    func testTVShowPosterURLsUseTheExpectedImageSizes() throws {
        let show = try JSONDecoder().decode(TVShow.self, from: Data(#"""
        {"id":3,"name":"Série","overview":"...","poster_path":"/tv.jpg"}
        """#.utf8))

        XCTAssertEqual(show.smallPosterURL?.absoluteString, "https://image.tmdb.org/t/p/w154/tv.jpg")
        XCTAssertEqual(show.largePosterURL?.absoluteString, "https://image.tmdb.org/t/p/w500/tv.jpg")
    }

    func testCastProfileURLUsesSmallImageSize() throws {
        let actor = try JSONDecoder().decode(Cast.self, from: Data(#"""
        {"id":4,"name":"Acteur","character":"Rôle","profile_path":"/face.jpg"}
        """#.utf8))

        XCTAssertEqual(actor.profileURL?.absoluteString, "https://image.tmdb.org/t/p/w200/face.jpg")
    }

    func testMissingOrNullTextFieldsDoNotBreakDecoding() throws {
        let movie = try JSONDecoder().decode(Movie.self, from: Data(#"""
        {"id":5,"title":null,"overview":null}
        """#.utf8))
        let show = try JSONDecoder().decode(TVShow.self, from: Data(#"""
        {"id":6}
        """#.utf8))
        let response = try JSONDecoder().decode(TMDBResponse<Movie>.self, from: Data(#"""
        {"page":1}
        """#.utf8))
        let credits = try JSONDecoder().decode(CreditsResponse.self, from: Data("{}".utf8))

        XCTAssertEqual(movie.title, "")
        XCTAssertEqual(movie.overview, "")
        XCTAssertEqual(show.name, "")
        XCTAssertTrue(response.results.isEmpty)
        XCTAssertTrue(credits.cast.isEmpty)
    }

    func testSynopsisFallbackCoversEmptyAndWhitespaceValues() {
        let noSnippet = FilmSerieItem(id: 1, kind: .movie, title: "Titre", snippet: nil,
                                      smallPosterURL: nil, largePosterURL: nil, url: nil)
        XCTAssertFalse(noSnippet.hasSynopsis)
        XCTAssertEqual(noSnippet.displaySynopsis, "Aucun synopsis disponible.")

        let empty = FilmSerieItem(id: 2, kind: .movie, title: "T", snippet: "   \n  ",
                                  smallPosterURL: nil, largePosterURL: nil, url: nil)
        XCTAssertFalse(empty.hasSynopsis)
        XCTAssertEqual(empty.displaySynopsis, "Aucun synopsis disponible.")

        let filled = FilmSerieItem(id: 3, kind: .series, title: "T", snippet: "Un vrai synopsis",
                                   smallPosterURL: nil, largePosterURL: nil, url: nil)
        XCTAssertTrue(filled.hasSynopsis)
        XCTAssertEqual(filled.displaySynopsis, "Un vrai synopsis")
    }

    func testBlankTitleGetsAFallback() {
        let item = FilmSerieItem(id: 1, kind: .movie, title: "  ", snippet: nil,
                                 smallPosterURL: nil, largePosterURL: nil, url: nil)
        XCTAssertEqual(item.displayTitle, "Sans titre")
    }
}
