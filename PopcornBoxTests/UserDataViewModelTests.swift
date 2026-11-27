import XCTest
@testable import PopcornBox

@MainActor
final class UserDataViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel(dataService: MockUserDataService) -> UserDataViewModel {
        UserDataViewModel(dataService: dataService)
    }

    private func makeMovieItem(id: Int = 101, title: String = "Film Test", kind: MediaType = .movie) -> FilmSerieItem {
        FilmSerieItem(
            id: id,
            kind: kind,
            title: title,
            snippet: "Synopsis de \(title)",
            smallPosterURL: URL(string: "https://example.com/small/\(id).jpg"),
            largePosterURL: URL(string: "https://example.com/poster/\(id).jpg"),
            url: URL(string: "https://www.themoviedb.org/movie/\(id)"),
            backdropURL: URL(string: "https://example.com/backdrop/\(id).jpg"),
            releaseYear: 2020,
            genreIDs: [28],
            rating: 7.5
        )
    }

    // MARK: - Toggle favorite

    func testToggleFavoriteAddsWhenNotFavorite() async {
        let dataService = MockUserDataService()
        dataService.isFavoriteResults = [false]
        dataService.addFavoriteResult = true
        let viewModel = makeViewModel(dataService: dataService)
        let item = makeMovieItem(id: 101, title: "Film Test")

        await viewModel.toggleFavorite(item)

        XCTAssertTrue(dataService.addFavoriteCalls.contains { $0.id == item.id })
        XCTAssertEqual(viewModel.favorites.count, 1)
    }

    func testToggleFavoriteRemovesWhenAlreadyFavorite() async {
        let dataService = MockUserDataService()
        dataService.isFavoriteResults = [true]
        dataService.removeFavoriteResult = true
        dataService.favorites = [
            Favorite(userId: "uid", itemId: 101, kind: .movie, title: "Film Test")
        ]
        let viewModel = makeViewModel(dataService: dataService)
        let item = makeMovieItem(id: 101, title: "Film Test")

        await viewModel.toggleFavorite(item)

        XCTAssertTrue(dataService.removeFavoriteCalls.contains { $0.itemId == 101 && $0.kind == .movie })
        XCTAssertTrue(viewModel.favorites.isEmpty)
    }

    func testToggleFavoriteFailureSetsError() async {
        let dataService = MockUserDataService()
        dataService.isFavoriteResults = [false]
        dataService.addFavoriteResult = false
        let viewModel = makeViewModel(dataService: dataService)
        let item = makeMovieItem()

        await viewModel.toggleFavorite(item)

        XCTAssertEqual(viewModel.errorMessage, "Impossible d'ajouter aux favoris.")
    }

    // MARK: - Save quiz result

    func testSaveQuizResultSavesScore() async {
        let dataService = MockUserDataService()
        dataService.saveQuizScoreResult = true
        let viewModel = makeViewModel(dataService: dataService)

        await viewModel.saveQuizResult(score: 8, total: 10)

        XCTAssertTrue(dataService.saveQuizScoreCalls.contains { $0.score == 8 && $0.total == 10 })
    }

    func testSaveQuizResultFailureSetsError() async {
        let dataService = MockUserDataService()
        dataService.saveQuizScoreResult = false
        let viewModel = makeViewModel(dataService: dataService)

        await viewModel.saveQuizResult(score: 5, total: 10)

        XCTAssertEqual(viewModel.errorMessage, "Impossible d'enregistrer le score.")
    }

    // MARK: - Is item favorite

    func testIsItemFavoriteDelegatesToService() async {
        let dataService = MockUserDataService()
        dataService.isFavoriteResults = [true]
        let viewModel = makeViewModel(dataService: dataService)
        let item = makeMovieItem()

        let result = await viewModel.isItemFavorite(item)

        XCTAssertTrue(result)
        XCTAssertEqual(dataService.isFavoriteCalls.count, 1)
        XCTAssertEqual(dataService.isFavoriteCalls.first?.itemId, 1)
        XCTAssertEqual(dataService.isFavoriteCalls.first?.kind, .movie)
    }
}
