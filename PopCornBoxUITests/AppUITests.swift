import XCTest

/// Tests d'interface utilisateur pour l'application hôte PopCornBox (version WidgetKit).
///
/// L'application hôte est une vue statique d'instructions. Ces tests vérifient
/// qu'elle se lance correctement et affiche tous ses éléments d'accessibilité.
final class AppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    @discardableResult
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 10) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Élément introuvable : \(element)")
        return element
    }

    // MARK: - Écran d'accueil de l'application hôte

    func testHostAppLaunchesAndShowsAllElements() {
        waitFor(element("host.root"))

        waitFor(element("host.logo"))
        waitFor(element("host.title"))
        waitFor(element("host.subtitle"))
        waitFor(element("host.instructions"))
        waitFor(element("host.widgetHint"))

        XCTAssertTrue(app.staticTexts["PopCornBox"].exists)
        XCTAssertTrue(app.staticTexts["Le catalogue est désormais disponible directement sur votre écran d'accueil."].exists)
        XCTAssertTrue(app.staticTexts["Appui long sur le widget pour choisir Films ou Séries."].exists)
    }

    func testHostAppShowsInstructions() {
        waitFor(element("host.root"))

        XCTAssertTrue(app.staticTexts["Quittez cette application et retournez sur l'écran d'accueil."].exists)
        XCTAssertTrue(app.staticTexts["Effectuez un appui long sur une zone vide."].exists)
        XCTAssertTrue(app.staticTexts["Touchez « + », recherchez PopCornBox et ajoutez le widget."].exists)
    }

    func testHostAppHasLogoAndTitle() {
        waitFor(element("host.root"))

        waitFor(element("host.logo"))
        waitFor(element("host.title"))
        XCTAssertTrue(app.images["host.logo"].exists)
        XCTAssertTrue(app.staticTexts["PopCornBox"].exists)
    }
}
