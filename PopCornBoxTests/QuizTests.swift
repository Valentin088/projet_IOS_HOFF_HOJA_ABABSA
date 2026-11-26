import XCTest
@testable import PopCornBox

/// Tests du quizz : générateur déterministe et machine à états du ViewModel.
@MainActor
final class QuizTests: XCTestCase {

    // MARK: - Client simulé

    @MainActor
    private final class MockQuizClient: TMDBProviding {
        enum MockError: LocalizedError {
            case network
            var errorDescription: String? { "Erreur réseau simulée" }
        }

        var movies: [FilmSerieItem] = []
        var series: [FilmSerieItem] = []
        var error: Error?
        var castByID: [Int: [Cast]] = [:]
        var forceEmptyCast = false

        private(set) var suggestCalls: [MediaType] = []
        private(set) var castFetchCalls: [Int] = []

        func suggest(mediaType: MediaType) async throws -> [FilmSerieItem] {
            suggestCalls.append(mediaType)
            if let error { throw error }
            return mediaType == .movie ? movies : series
        }

        func search(mediaType: MediaType, query: String) async throws -> [FilmSerieItem] {
            mediaType == .movie ? movies : series
        }

        func fetchCast(mediaType: MediaType, id: Int) async throws -> [Cast] {
            castFetchCalls.append(id)
            if let error { throw error }
            if forceEmptyCast { return [] }
            return castByID[id] ?? quizCast(for: id)
        }
    }

    // MARK: - Utilitaires

    private func makeLoadedViewModel(
        movies: Int = 6,
        series: Int = 6,
        questionCount: Int = 10,
        sourceCount: Int = 12,
        configure: (MockQuizClient) -> Void = { _ in }
    ) async -> (viewModel: QuizViewModel, client: MockQuizClient) {
        let (movieItems, seriesItems) = quizCatalog(movies: movies, series: series)
        let client = MockQuizClient()
        client.movies = movieItems
        client.series = seriesItems
        configure(client)

        let viewModel = QuizViewModel(
            client: client,
            questionCount: questionCount,
            sourceCount: sourceCount
        )
        await viewModel.load()
        return (viewModel, client)
    }

    // MARK: - Modèle

    func testQuestionCorrectAnswer() {
        let question = QuizQuestion(
            id: "q1",
            kind: .image,
            prompt: "Quel est ce film ?",
            options: ["A", "B", "C", "D"],
            correctAnswerIndex: 2,
            imageURL: nil,
            imageIsPortrait: false,
            mediaKind: .movie,
            explanation: "Explication"
        )

        XCTAssertEqual(question.correctAnswer, "C")
        XCTAssertTrue(question.isCorrect(answerIndex: 2))
        XCTAssertFalse(question.isCorrect(answerIndex: 0))
    }

    func testQuestionKindsHaveFrenchLabels() {
        XCTAssertEqual(QuizQuestionKind.actor.label, "Acteurs")
        XCTAssertEqual(QuizQuestionKind.character.label, "Personnages")
        XCTAssertEqual(QuizQuestionKind.year.label, "Année")
    }

    // MARK: - Générateur

    func testGeneratorReturnsEmptyWhenFewerThanFourDistinctTitles() {
        let items = [
            quizItem(id: 1, title: "Film 1", kind: .movie),
            quizItem(id: 2, title: "Film 2", kind: .movie),
            quizItem(id: 3, title: "Série 1", kind: .series)
        ]

        XCTAssertTrue(QuizGenerator.makeQuestions(from: quizSources(from: items)).isEmpty)
    }

    func testGeneratorIgnoresDuplicateAndEmptyTitles() {
        let items = [
            quizItem(id: 1, title: "Film 1", kind: .movie),
            quizItem(id: 2, title: "film 1", kind: .movie),
            quizItem(id: 3, title: "   ", kind: .movie),
            quizItem(id: 4, title: "Film 2", kind: .movie),
            quizItem(id: 5, title: "Film 3", kind: .movie),
            quizItem(id: 6, title: "Film 4", kind: .movie),
            quizItem(id: 7, title: "Film 5", kind: .movie)
        ]

        let questions = QuizGenerator.makeQuestions(from: quizSources(from: items))

        XCTAssertEqual(questions.count, QuizGenerator.defaultQuestionCount)
        XCTAssertFalse(Set(questions.compactMap(\.correctAnswer)).contains("film 1"))
    }

    func testGeneratorRespectsRequestedCountAndCreatesUniqueIDs() {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 5
        )

        XCTAssertEqual(questions.count, 5)
        XCTAssertEqual(Set(questions.map(\.id)).count, 5)
    }

    func testGeneratorCapsQuestionCount() {
        let (movies, series) = quizCatalog(movies: 2, series: 2)
        let sources = quizSources(from: QuizGenerator.merge(movies: movies, series: series))
        let questions = QuizGenerator.makeQuestions(from: sources, count: 50)

        XCTAssertGreaterThan(questions.count, 0)
        XCTAssertLessThanOrEqual(questions.count, sources.count * QuizQuestionKind.allCases.count)
    }

    func testEachQuestionHasFourDistinctOptionsAndAValidAnswer() {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        XCTAssertEqual(questions.count, 10)
        for question in questions {
            XCTAssertEqual(question.options.count, QuizGenerator.optionCount)
            XCTAssertEqual(Set(question.options).count, QuizGenerator.optionCount)
            XCTAssertTrue(question.options.indices.contains(question.correctAnswerIndex))
            XCTAssertFalse(question.explanation.isEmpty)
        }
    }

    func testCorrectAnswerPositionVariesBetweenQuestions() {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 8
        )

        XCTAssertGreaterThan(Set(questions.map(\.correctAnswerIndex)).count, 1)
    }

    func testGeneratorCoversAllQuestionKinds() {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        for kind in QuizQuestionKind.allCases {
            XCTAssertTrue(questions.contains { $0.kind == kind }, "Le type \(kind.rawValue) devrait apparaître")
        }
    }

    func testImageQuestionUsesBackdropAndNeverPoster() throws {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .image }))
        XCTAssertEqual(question.imageURL, URL(string: "https://example.com/backdrop/1.jpg"))
        XCTAssertFalse(question.imageIsPortrait)

        for question in questions {
            let url = question.imageURL?.absoluteString ?? ""
            XCTAssertFalse(url.contains("/poster/"))
            XCTAssertFalse(url.contains("/small/"))
        }
    }

    func testActorQuestionUsesCastNameAndBackdrop() throws {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .actor }))
        XCTAssertTrue(question.prompt.contains("Quel acteur interprète"))
        XCTAssertTrue(try XCTUnwrap(question.correctAnswer).hasPrefix("Acteur "))
        XCTAssertTrue(question.imageURL?.absoluteString.contains("/backdrop/") == true)
    }

    func testCharacterQuestionUsesPortraitAndRole() throws {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .character }))
        XCTAssertTrue(question.prompt.contains("Quel personnage"))
        XCTAssertTrue(try XCTUnwrap(question.correctAnswer).hasPrefix("Rôle "))
        XCTAssertTrue(question.imageIsPortrait)
        XCTAssertTrue(question.imageURL?.absoluteString.contains("/portrait/") == true)
    }

    func testYearQuestionUsesReleaseYear() throws {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let allYears = Set((movies + series).compactMap(\.releaseYear))
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .year }))
        let answer = try XCTUnwrap(question.correctAnswer)
        XCTAssertEqual(answer.count, 4)
        XCTAssertTrue(allYears.contains(Int(answer) ?? -1))
    }

    func testGenreQuestionUsesFrenchGenreName() throws {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .genre }))
        XCTAssertTrue(QuizGenerator.genres.values.contains(try XCTUnwrap(question.correctAnswer)))
    }

    func testRatingQuestionIsFormatted() throws {
        let (movies, series) = quizCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: quizSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let answer = try XCTUnwrap(questions.first(where: { $0.kind == .rating })?.correctAnswer)
        XCTAssertTrue(answer.hasSuffix(" / 10"))
        XCTAssertFalse(answer.contains("."))
    }

    func testMergeAlternatesMoviesAndSeries() {
        let (movies, series) = quizCatalog(movies: 2, series: 2)
        XCTAssertEqual(
            QuizGenerator.merge(movies: movies, series: series).map(\.title),
            ["Film 1", "Série 1", "Film 2", "Série 2"]
        )
    }

    func testMergeHandlesUnequalLists() {
        let (movies, series) = quizCatalog(movies: 3, series: 1)
        XCTAssertEqual(
            QuizGenerator.merge(movies: movies, series: series).map(\.title),
            ["Film 1", "Série 1", "Film 2", "Film 3"]
        )
    }

    // MARK: - ViewModel

    func testLoadBuildsQuestionsFromBothMoviesAndSeriesAndFetchesCast() async {
        let (viewModel, client) = await makeLoadedViewModel()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.questions.count, 10)
        XCTAssertEqual(viewModel.currentQuestion?.mediaKind, .movie)
        XCTAssertEqual(client.suggestCalls, [.movie, .series])
        XCTAssertEqual(client.castFetchCalls.count, 12)
        XCTAssertEqual(viewModel.progress, 0.1)
    }

    func testAnswerIncreasesScoreOnlyOnce() async {
        let (viewModel, _) = await makeLoadedViewModel(questionCount: 2)
        let correctIndex = viewModel.currentQuestion!.correctAnswerIndex

        viewModel.answer(index: correctIndex)
        XCTAssertEqual(viewModel.score, 1)

        viewModel.answer(index: (correctIndex + 1) % QuizGenerator.optionCount)
        XCTAssertEqual(viewModel.score, 1)
        XCTAssertEqual(viewModel.selectedAnswerIndex, correctIndex)
    }

    func testWrongAnswerRevealsCorrectOne() async {
        let (viewModel, _) = await makeLoadedViewModel(questionCount: 2)
        let question = viewModel.currentQuestion!
        let wrongIndex = (question.correctAnswerIndex + 1) % QuizGenerator.optionCount

        viewModel.answer(index: wrongIndex)

        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.feedback, .incorrect(correctAnswer: question.correctAnswer!))
    }

    func testAnswerIgnoresOutOfRangeIndex() async {
        let (viewModel, _) = await makeLoadedViewModel()
        viewModel.answer(index: 99)

        XCTAssertNil(viewModel.selectedAnswerIndex)
        XCTAssertEqual(viewModel.score, 0)
    }

    func testNextAdvancesThenFinishesTheGame() async {
        let (viewModel, _) = await makeLoadedViewModel(questionCount: 2)

        viewModel.answer(index: viewModel.currentQuestion!.correctAnswerIndex)
        viewModel.next()
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertNil(viewModel.selectedAnswerIndex)

        viewModel.answer(index: viewModel.currentQuestion!.correctAnswerIndex)
        viewModel.next()
        XCTAssertEqual(viewModel.state, .finished)
        XCTAssertEqual(viewModel.score, 2)
    }

    func testNextIsIgnoredUntilAnAnswerIsGiven() async {
        let (viewModel, _) = await makeLoadedViewModel(questionCount: 2)
        viewModel.next()

        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.state, .ready)
    }

    func testRestartResetsScoreAndKeepsQuestions() async {
        let (viewModel, _) = await makeLoadedViewModel(questionCount: 2)
        let initialQuestions = viewModel.questions

        for _ in 0..<2 {
            viewModel.answer(index: viewModel.currentQuestion!.correctAnswerIndex)
            viewModel.next()
        }
        XCTAssertEqual(viewModel.state, .finished)

        viewModel.restart()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.questions, initialQuestions)
    }

    func testLoadMapsNetworkErrorToErrorState() async {
        let (viewModel, _) = await makeLoadedViewModel { client in
            client.error = MockQuizClient.MockError.network
        }

        XCTAssertEqual(viewModel.state, .error("Une erreur est survenue. Réessayez."))
        XCTAssertTrue(viewModel.questions.isEmpty)
    }

    func testLoadFailsClearlyWhenCatalogIsTooSmall() async {
        let (viewModel, _) = await makeLoadedViewModel(movies: 2, series: 1)

        XCTAssertEqual(
            viewModel.state,
            .error("Pas assez d'informations sur les films et séries pour lancer le quizz.")
        )
    }

    func testMissingCastStillProducesOtherQuestions() async {
        let (viewModel, _) = await makeLoadedViewModel { client in
            client.forceEmptyCast = true
        }

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertFalse(viewModel.questions.isEmpty)
        XCTAssertFalse(viewModel.questions.contains { $0.kind == .actor })
        XCTAssertFalse(viewModel.questions.contains { $0.kind == .character })
    }

    func testReloadReplacesQuestionsAndResetsProgress() async {
        let (viewModel, client) = await makeLoadedViewModel(questionCount: 3)
        viewModel.answer(index: 0)
        let firstQuestionID = viewModel.questions.first?.id

        await viewModel.load()

        XCTAssertEqual(viewModel.score, 0)
        XCTAssertNil(viewModel.selectedAnswerIndex)
        XCTAssertEqual(viewModel.questions.first?.id, firstQuestionID)
        XCTAssertEqual(client.suggestCalls, [.movie, .series, .movie, .series])
        XCTAssertEqual(client.castFetchCalls.count, 24)
    }
}

// MARK: - Fixtures locales

@MainActor
private func quizItem(id: Int, title: String, kind: MediaType) -> FilmSerieItem {
    let genres = [28, 35, 18, 878, 53, 12]
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
        genreIDs: [genres[id % genres.count]],
        rating: 6.1 + Double(id % 8) * 0.4
    )
}

@MainActor
private func quizCast(for id: Int) -> [Cast] {
    [
        Cast(id: id * 10 + 1, name: "Acteur \(id) A", character: "Rôle \(id) A",
             profilePath: "/portrait/\(id)a.jpg"),
        Cast(id: id * 10 + 2, name: "Acteur \(id) B", character: "Rôle \(id) B",
             profilePath: "/portrait/\(id)b.jpg")
    ]
}

@MainActor
private func quizCatalog(movies: Int, series: Int) -> ([FilmSerieItem], [FilmSerieItem]) {
    let movieItems = (1...movies).map { quizItem(id: $0, title: "Film \($0)", kind: .movie) }
    let seriesItems = (1...series).map { quizItem(id: 100 + $0, title: "Série \($0)", kind: .series) }
    return (movieItems, seriesItems)
}

@MainActor
private func quizSources(from items: [FilmSerieItem]) -> [QuizSource] {
    items.map { QuizSource(item: $0, cast: quizCast(for: $0.id)) }
}
