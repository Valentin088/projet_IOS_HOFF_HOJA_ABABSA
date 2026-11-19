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
}
