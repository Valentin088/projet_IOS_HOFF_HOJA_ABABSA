import XCTest
@testable import ok

@MainActor
final class QuizTests: XCTestCase {

    // MARK: - Utilitaire

    private func makeLoadedViewModel(
        movies: Int = 6,
        series: Int = 6,
        questionCount: Int = 10,
        sourceCount: Int = 12,
        configure: (MockTMDBClient) -> Void = { _ in }
    ) async -> (viewModel: QuizViewModel, client: MockTMDBClient) {
        let (movieItems, seriesItems) = makeCatalog(movies: movies, series: series)
        let client = MockTMDBClient()
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

    // MARK: - Générateur : questions classiques

    func testGeneratorReturnsEmptyWhenFewerThanFourDistinctTitles() {
        let items = [
            makeItem(id: 1, title: "Film 1", kind: .movie),
            makeItem(id: 2, title: "Film 2", kind: .movie),
            makeItem(id: 3, title: "Série 1", kind: .series)
        ]

        XCTAssertTrue(QuizGenerator.makeQuestions(from: makeSources(from: items)).isEmpty)
    }

    func testGeneratorIgnoresDuplicateAndEmptyTitles() {
        let items = [
            makeItem(id: 1, title: "Film 1", kind: .movie),
            makeItem(id: 2, title: "film 1", kind: .movie),
            makeItem(id: 3, title: "   ", kind: .movie),
            makeItem(id: 4, title: "Film 2", kind: .movie),
            makeItem(id: 5, title: "Film 3", kind: .movie),
            makeItem(id: 6, title: "Film 4", kind: .movie),
            makeItem(id: 7, title: "Film 5", kind: .movie)
        ]

        let questions = QuizGenerator.makeQuestions(from: makeSources(from: items))

        XCTAssertEqual(questions.count, QuizGenerator.defaultQuestionCount)
        let titles = Set(questions.compactMap(\.correctAnswer))
        XCTAssertFalse(titles.contains("film 1"))
    }

    func testGeneratorRespectsRequestedCountAndCreatesUniqueIDs() {
        let (movies, series) = makeCatalog(movies: 6, series: 6)

        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 5
        )

        XCTAssertEqual(questions.count, 5)
        XCTAssertEqual(Set(questions.map(\.id)).count, 5)
    }

    func testGeneratorCapsQuestionCount() {
        let (movies, series) = makeCatalog(movies: 2, series: 2)
        let sources = makeSources(from: QuizGenerator.merge(movies: movies, series: series))

        let questions = QuizGenerator.makeQuestions(from: sources, count: 50)

        XCTAssertGreaterThan(questions.count, 0)
        XCTAssertLessThanOrEqual(questions.count, sources.count * QuizQuestionKind.allCases.count)
    }

    func testEachQuestionHasFourDistinctOptionsAndAValidAnswer() {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        XCTAssertEqual(questions.count, 10)
        for question in questions {
            XCTAssertEqual(question.options.count, QuizGenerator.optionCount)
            XCTAssertEqual(Set(question.options).count, QuizGenerator.optionCount)
            XCTAssertTrue(question.options.indices.contains(question.correctAnswerIndex))
            XCTAssertEqual(question.correctAnswer, question.options[question.correctAnswerIndex])
            XCTAssertFalse(question.explanation.isEmpty)
        }
    }

    func testCorrectAnswerPositionVariesBetweenQuestions() {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 8
        )

        XCTAssertGreaterThan(Set(questions.map(\.correctAnswerIndex)).count, 1)
    }

    // MARK: - Générateur : nouveaux types de questions

    func testGeneratorCoversAllQuestionKinds() {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let kinds = Set(questions.map(\.kind))
        for kind in QuizQuestionKind.allCases {
            XCTAssertTrue(kinds.contains(kind), "Le type \(kind.rawValue) devrait apparaître")
        }
    }

    func testImageQuestionUsesBackdropAndNeverPoster() throws {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let imageQuestion = try XCTUnwrap(questions.first(where: { $0.kind == .image }))
        XCTAssertEqual(imageQuestion.prompt, "Quel est le titre de ce film ?")
        XCTAssertEqual(imageQuestion.imageURL, URL(string: "https://example.com/backdrop/1.jpg"))
        XCTAssertFalse(imageQuestion.imageIsPortrait)

        for question in questions {
            let url = question.imageURL?.absoluteString ?? ""
            XCTAssertFalse(url.contains("/poster/"), "Aucune affiche avec titre ne doit être affichée")
            XCTAssertFalse(url.contains("/small/"))
        }
    }

    func testActorQuestionUsesCastNameAndBackdrop() throws {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .actor }))
        XCTAssertTrue(question.prompt.contains("Quel acteur interprète"))
        XCTAssertTrue(try XCTUnwrap(question.correctAnswer).hasPrefix("Acteur "))
        XCTAssertTrue(question.imageURL?.absoluteString.contains("/backdrop/") == true)
    }

    func testCharacterQuestionUsesPortraitAndRole() throws {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .character }))
        XCTAssertTrue(question.prompt.contains("Quel personnage"))
        XCTAssertTrue(try XCTUnwrap(question.correctAnswer).hasPrefix("Rôle "))
        XCTAssertTrue(question.imageIsPortrait)
        XCTAssertTrue(question.imageURL?.absoluteString.contains("/portrait/") == true)
    }

    func testYearQuestionUsesReleaseYear() throws {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let allYears = Set((movies + series).compactMap(\.releaseYear))
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .year }))
        let answer = try XCTUnwrap(question.correctAnswer)
        XCTAssertEqual(answer.count, 4)
        XCTAssertTrue(allYears.contains(Int(answer) ?? -1))
    }

    func testGenreQuestionUsesFrenchGenreName() throws {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .genre }))
        let answer = try XCTUnwrap(question.correctAnswer)
        XCTAssertTrue(QuizGenerator.genres.values.contains(answer))
        XCTAssertTrue(question.prompt.contains("genre principal"))
    }

    func testRatingQuestionIsFormatted() throws {
        let (movies, series) = makeCatalog(movies: 6, series: 6)
        let questions = QuizGenerator.makeQuestions(
            from: makeSources(from: QuizGenerator.merge(movies: movies, series: series)),
            count: 10
        )

        let question = try XCTUnwrap(questions.first(where: { $0.kind == .rating }))
        let answer = try XCTUnwrap(question.correctAnswer)
        XCTAssertTrue(answer.hasSuffix(" / 10"))
        XCTAssertFalse(answer.contains("."))
    }

    func testMergeAlternatesMoviesAndSeries() {
        let (movies, series) = makeCatalog(movies: 2, series: 2)

        XCTAssertEqual(
            QuizGenerator.merge(movies: movies, series: series).map(\.title),
            ["Film 1", "Série 1", "Film 2", "Série 2"]
        )
    }

    func testMergeHandlesUnequalLists() {
        let (movies, series) = makeCatalog(movies: 3, series: 1)

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
        XCTAssertEqual(viewModel.feedback, .correct(viewModel.currentQuestion!.explanation))

        // Une seconde réponse sur la même question est ignorée.
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
        XCTAssertEqual(viewModel.score, 1)
        XCTAssertTrue(viewModel.isLastQuestion)

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

        viewModel.answer(index: viewModel.currentQuestion!.correctAnswerIndex)
        viewModel.next()
        viewModel.answer(index: viewModel.currentQuestion!.correctAnswerIndex)
        viewModel.next()
        XCTAssertEqual(viewModel.state, .finished)

        viewModel.restart()

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertNil(viewModel.selectedAnswerIndex)
        XCTAssertEqual(viewModel.questions, initialQuestions)
    }

    func testLoadMapsNetworkErrorToErrorState() async {
        let (viewModel, _) = await makeLoadedViewModel { client in
            client.error = MockTMDBClient.MockError.network
        }

        XCTAssertEqual(viewModel.state, .error("Erreur réseau simulée"))
        XCTAssertTrue(viewModel.questions.isEmpty)
    }

    func testLoadFailsClearlyWhenCatalogIsTooSmall() async {
        let (viewModel, _) = await makeLoadedViewModel(movies: 2, series: 1)

        XCTAssertEqual(
            viewModel.state,
            .error("Pas assez d'informations sur les films et séries pour lancer le quizz.")
        )
        XCTAssertTrue(viewModel.questions.isEmpty)
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
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.questions.first?.id, firstQuestionID)
        XCTAssertEqual(client.suggestCalls, [.movie, .series, .movie, .series])
        XCTAssertEqual(client.castFetchCalls.count, 24)
    }
}
