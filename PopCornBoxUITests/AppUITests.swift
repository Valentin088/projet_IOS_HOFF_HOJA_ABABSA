import XCTest

/// Tests du parcours utilisateur. Les données sont simulées via des arguments de lancement
/// (`--uitests-mock`, `--uitests-empty`, `--uitests-error`) pour ne jamais dépendre du réseau.
final class AppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launchApp(extraArguments: [String] = []) {
        app.launchArguments = ["--uitests-mock"] + extraArguments
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @discardableResult
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 15) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Élément introuvable : \(element)")
        return element
    }

    // MARK: - Accueil

    func testHomeOffersMoviesAndSeriesEntries() {
        launchApp()

        waitFor(element("home.movies"))
        waitFor(element("home.series"))
        waitFor(element("home.quiz"))
    }

    func testQuizDisplaysAQuestionAndAcceptsAnAnswer() {
        launchApp()
        waitFor(element("home.quiz")).tap()

        waitFor(element("quiz.root"))
        let firstAnswer = waitFor(element("quiz.answer.0"))
        firstAnswer.tap()

        waitFor(element("quiz.next"))
        XCTAssertTrue(element("quiz.feedback.correct").exists || element("quiz.feedback.incorrect").exists)
    }

    // MARK: - Films

    func testMoviesListDisplaysItemsAndHandlesEmptySynopsis() {
        launchApp()
        waitFor(element("home.movies")).tap()

        waitFor(element("item.101"))
        waitFor(element("item.102"))

        XCTAssertTrue(app.staticTexts["Film UI Test"].exists)
        XCTAssertTrue(app.staticTexts["Film sans synopsis"].exists)
    }

    func testTappingAMovieOpensItsDetailsWithSynopsisFallback() {
        launchApp()
        waitFor(element("home.movies")).tap()
        waitFor(element("item.102")).tap()

        waitFor(element("details.root"))
        XCTAssertTrue(app.staticTexts["Aucun synopsis disponible."].exists)
        XCTAssertTrue(app.staticTexts["Acteur UI Test"].exists)
    }

    func testEmptyMovieListShowsAFriendlyMessage() {
        launchApp(extraArguments: ["--uitests-empty"])
        waitFor(element("home.movies")).tap()

        waitFor(app.staticTexts["Aucun film trouvé"])
        XCTAssertFalse(app.staticTexts["Une erreur est survenue"].exists)
    }

    func testNetworkErrorOffersARetryButton() {
        launchApp(extraArguments: ["--uitests-error"])
        waitFor(element("home.movies")).tap()

        waitFor(app.staticTexts["Une erreur est survenue"])
        waitFor(app.staticTexts["Le catalogue est momentanément indisponible."])

        let retry = app.buttons["Réessayer"]
        waitFor(retry)
        retry.tap()
        waitFor(retry)
    }

    // MARK: - Séries

    func testSeriesListDisplaysSeriesAndDetails() {
        launchApp()
        waitFor(element("home.series")).tap()
        waitFor(element("item.201"))

        XCTAssertTrue(app.staticTexts["Série UI Test"].exists)

        element("item.201").tap()
        waitFor(element("details.root"))
        XCTAssertTrue(app.staticTexts["Acteur UI Test"].exists)
    }

    func testEmptySeriesListShowsAFriendlyMessage() {
        launchApp(extraArguments: ["--uitests-empty"])
        waitFor(element("home.series")).tap()

        waitFor(app.staticTexts["Aucune série trouvée"])
    }

    // MARK: - Recherche

    func testSearchMoviesFiltersResults() {
        launchApp()
        waitFor(element("home.movies")).tap()

        // Ouvrir le champ de recherche et saisir une requête
        let searchField = app.searchFields.firstMatch
        waitFor(searchField)
        searchField.tap()
        searchField.typeText("Film UI Test")

        waitFor(element("item.101"), timeout: 10)
        XCTAssertTrue(app.staticTexts["Film UI Test"].exists)
        XCTAssertFalse(app.staticTexts["Film sans synopsis"].exists)
    }

    func testSearchSeriesFiltersResults() {
        launchApp()
        waitFor(element("home.series")).tap()

        let searchField = app.searchFields.firstMatch
        waitFor(searchField)
        searchField.tap()
        searchField.typeText("Série UI Test")

        waitFor(element("item.201"), timeout: 10)
        XCTAssertTrue(app.staticTexts["Série UI Test"].exists)
    }

    // MARK: - Quiz complet

    func testQuizFullFlowReachesResultScreen() {
        launchApp()
        waitFor(element("home.quiz")).tap()

        waitFor(element("quiz.root"), timeout: 10)

        // Répondre à chaque question jusqu'à la fin
        for _ in 1...15 {
            let firstAnswer = waitFor(element("quiz.answer.0"), timeout: 10)
            firstAnswer.tap()

            // Attendre le feedback
            _ = element("quiz.feedback.correct").waitForExistence(timeout: 5)
                || element("quiz.feedback.incorrect").waitForExistence(timeout: 5)

            // Si l'écran de résultat est affiché, on a terminé
            if app.staticTexts["Partie terminée !"].waitForExistence(timeout: 1) {
                break
            }

            // Sinon passer à la question suivante
            let nextButton = element("quiz.next")
            if nextButton.waitForExistence(timeout: 5) {
                nextButton.tap()
            } else {
                break
            }
        }

        XCTAssertTrue(app.staticTexts["Partie terminée !"].exists, "L'écran de résultat devrait s'afficher")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label MATCHES %@", "\\d+ / \\d+")).firstMatch.exists, "Le score devrait s'afficher")
    }

    func testQuizReplayRestartsFromFirstQuestion() {
        launchApp()
        waitFor(element("home.quiz")).tap()

        waitFor(element("quiz.root"), timeout: 10)

        // Aller jusqu'à la fin du quiz
        for _ in 1...15 {
            waitFor(element("quiz.answer.0"), timeout: 10).tap()
            _ = element("quiz.feedback.correct").waitForExistence(timeout: 5)
                || element("quiz.feedback.incorrect").waitForExistence(timeout: 5)

            if app.staticTexts["Partie terminée !"].waitForExistence(timeout: 1) {
                break
            }

            if element("quiz.next").waitForExistence(timeout: 5) {
                element("quiz.next").tap()
            } else {
                break
            }
        }

        waitFor(app.staticTexts["Partie terminée !"], timeout: 10)

        // Rejouer
        let replay = element("quiz.replay")
        waitFor(replay)
        replay.tap()

        // Doit revenir à la première question
        waitFor(element("quiz.root"), timeout: 10)
        waitFor(element("quiz.answer.0"), timeout: 10)
        XCTAssertFalse(app.staticTexts["Partie terminée !"].exists)
    }

    // MARK: - À propos

    func testHomeShowsAboutSection() {
        launchApp()
        waitFor(element("home.movies")) // s'assurer que l'écran d'accueil est chargé

        // L'écran d'accueil est la liste principale, naviguer vers "À propos"
        waitFor(app.navigationBars["PopCornBox"])
        // Le lien "À propos" est dans la section "PopCornBox"
        let aboutLink = app.buttons["À propos"]
        waitFor(aboutLink)
        aboutLink.tap()

        waitFor(element("home.logo"), timeout: 10)
        waitFor(element("home.title"), timeout: 10)
        XCTAssertTrue(app.staticTexts["PopCornBox"].exists)
        XCTAssertTrue(app.staticTexts["Les films et séries du moment, directement sur votre poignet."].exists)
    }
}
