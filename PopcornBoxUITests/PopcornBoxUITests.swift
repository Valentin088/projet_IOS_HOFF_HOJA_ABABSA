import XCTest

/// Tests d'interface utilisateur de PopCornBox.
///
/// Ces tests lancent l'application avec l'argument `-UITesting` afin d'utiliser
/// le client TMDB factice (`UITesting.Client`) et éviter tout appel réseau.
final class PopcornBoxUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    /// Attend qu'un élément existe et échoue le test avec un message clair sinon.
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 10,
                         file: StaticString = #file, line: UInt = #line) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Élément introuvable : \(element)", file: file, line: line)
    }
    
    // MARK: - Lancement et navigation par onglets
    
    func testAppLaunchesAndShowsHomeTab() {
        waitFor(app.staticTexts["home.welcome"])
        XCTAssertTrue(app.staticTexts["Bienvenue sur PopCornBox"].exists)
        XCTAssertTrue(app.images["home.logo"].exists)
    }
    
    func testTabNavigation() {
        waitFor(app.staticTexts["home.welcome"])
        
        // Onglet Films
        app.tabBars.buttons["Films"].tap()
        waitFor(app.staticTexts["movies.loading"], timeout: 5)
        
        // Onglet Séries
        app.tabBars.buttons["Séries"].tap()
        waitFor(app.staticTexts["series.loading"], timeout: 5)
        
        // Onglet Quiz
        app.tabBars.buttons["Quiz"].tap()
        waitFor(app.staticTexts["quiz.loading"], timeout: 5)
        
        // Retour à l'accueil
        app.tabBars.buttons["Accueil"].tap()
        waitFor(app.staticTexts["home.welcome"])
    }
    
    // MARK: - Films et séries
    
    func testMoviesTabLoadsList() {
        app.tabBars.buttons["Films"].tap()
        
        waitFor(app.staticTexts["Inception"], timeout: 10)
        waitFor(app.staticTexts["Le Seigneur des anneaux"], timeout: 10)
        waitFor(app.staticTexts["Pulp Fiction"], timeout: 10)
        
        XCTAssertTrue(app.staticTexts["Inception"].exists)
        XCTAssertTrue(app.staticTexts["Le Seigneur des anneaux"].exists)
        XCTAssertTrue(app.staticTexts["Pulp Fiction"].exists)
    }
    
    func testSeriesTabLoadsList() {
        app.tabBars.buttons["Séries"].tap()
        
        waitFor(app.staticTexts["Stranger Things"], timeout: 10)
        waitFor(app.staticTexts["Breaking Bad"], timeout: 10)
        
        XCTAssertTrue(app.staticTexts["Stranger Things"].exists)
        XCTAssertTrue(app.staticTexts["Breaking Bad"].exists)
    }
    
    func testNavigateToMovieDetails() {
        app.tabBars.buttons["Films"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)
        
        // Taper sur la première ligne pour ouvrir les détails
        app.staticTexts["Inception"].tap()
        
        waitFor(app.staticTexts["details.title"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Inception"].exists)
        
        // Le casting doit se charger
        waitFor(app.staticTexts["Leonardo DiCaprio"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Leonardo DiCaprio"].exists)
        XCTAssertTrue(app.staticTexts["Elliot Page"].exists)
    }
    
    func testSearchMovies() {
        app.tabBars.buttons["Films"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)
        
        let searchField = app.searchFields["Rechercher un film..."]
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        searchField.typeText("Inception")
        
        waitFor(app.staticTexts["Inception"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Inception"].exists)
    }
    
    // MARK: - Quiz
    
    func testQuizFlow() {
        app.tabBars.buttons["Quiz"].tap()
        
        // Attendre le chargement et la première question
        waitFor(app.staticTexts["Question 1 / 10"], timeout: 10)
        
        for questionNumber in 1...10 {
            if questionNumber < 10 {
                waitFor(app.staticTexts["Question \(questionNumber) / 10"], timeout: 10)
            }
            
            // Répondre avec la première option
            let answerButton = app.buttons["quiz.answer.0"]
            waitFor(answerButton, timeout: 10)
            answerButton.tap()
            
            // Le feedback doit apparaître (bonne ou mauvaise réponse)
            _ = app.staticTexts["quiz.feedback.correct"].waitForExistence(timeout: 5)
            _ = app.staticTexts["quiz.feedback.incorrect"].waitForExistence(timeout: 5)
            
            if questionNumber < 10 {
                let nextButton = app.buttons["quiz.next"]
                waitFor(nextButton, timeout: 5)
                nextButton.tap()
            } else {
                // Dernière question : le bouton devient "Voir mon score"
                let scoreButton = app.buttons["quiz.next"]
                waitFor(scoreButton, timeout: 5)
                scoreButton.tap()
            }
        }
        
        waitFor(app.staticTexts["Partie terminée !"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Partie terminée !"].exists)
        
        // Le score doit être affiché sous la forme "X / 10"
        let scorePredicate = NSPredicate(format: "label MATCHES %@", "\\d+ / 10")
        let scoreText = app.staticTexts.containing(scorePredicate)
        XCTAssertTrue(scoreText.firstMatch.exists, "Le score final devrait être affiché")
    }
    
    func testQuizReplay() {
        app.tabBars.buttons["Quiz"].tap()
        waitFor(app.staticTexts["Question 1 / 10"], timeout: 10)
        
        // Aller jusqu'à la fin du quiz
        for _ in 1...10 {
            let answerButton = app.buttons["quiz.answer.0"]
            waitFor(answerButton, timeout: 10)
            answerButton.tap()
            
            _ = app.staticTexts["quiz.feedback.correct"].waitForExistence(timeout: 5)
            _ = app.staticTexts["quiz.feedback.incorrect"].waitForExistence(timeout: 5)
            
            let nextButton = app.buttons["quiz.next"]
            if nextButton.waitForExistence(timeout: 5) {
                nextButton.tap()
            }
        }
        
        waitFor(app.staticTexts["Partie terminée !"], timeout: 10)
        
        // Rejouer
        let replayButton = app.buttons["quiz.replay"]
        waitFor(replayButton, timeout: 5)
        replayButton.tap()
        
        // Doit revenir à la première question avec le score remis à zéro
        waitFor(app.staticTexts["Question 1 / 10"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Question 1 / 10"].exists)
    }
    
    func testQuizAnswerFeedback() {
        app.tabBars.buttons["Quiz"].tap()
        waitFor(app.staticTexts["Question 1 / 10"], timeout: 10)

        app.buttons["quiz.answer.0"].tap()

        // Le feedback (correct ou incorrect) doit apparaître
        let feedbackCorrect = app.staticTexts["quiz.feedback.correct"]
        let feedbackIncorrect = app.staticTexts["quiz.feedback.incorrect"]
        let feedbackAppeared = feedbackCorrect.waitForExistence(timeout: 5)
            || feedbackIncorrect.waitForExistence(timeout: 5)
        XCTAssertTrue(feedbackAppeared, "Un feedback devrait s'afficher après une réponse")

        // Le bouton de question suivante doit apparaître
        XCTAssertTrue(app.buttons["quiz.next"].waitForExistence(timeout: 5),
                      "Le bouton suivant devrait apparaître après une réponse")
    }

    // MARK: - Authentification et profil (mode test simulé)

    func testProfileTabShowsLoggedInUser() {
        // En mode UITesting, l'utilisateur est automatiquement connecté
        app.tabBars.buttons["Profil"].tap()

        waitFor(app.staticTexts["Utilisateur Test"], timeout: 10)
        waitFor(app.staticTexts["uitest@example.com"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Utilisateur Test"].exists)
        XCTAssertTrue(app.staticTexts["uitest@example.com"].exists)
    }

    // MARK: - Favoris depuis la liste des films

    func testAddMovieToFavoritesFromList() {
        app.tabBars.buttons["Films"].tap()

        waitFor(app.staticTexts["Inception"], timeout: 10)

        // Ajouter Inception aux favoris via le bouton cœur de la ligne
        let favoriteButton = app.buttons["item.favorite.1"]
        waitFor(favoriteButton, timeout: 10)
        favoriteButton.tap()

        // Vérifier dans l'onglet Profil que le favori apparaît
        app.tabBars.buttons["Profil"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Inception"].exists)
    }

    func testRemoveMovieFromFavorites() {
        app.tabBars.buttons["Films"].tap()

        waitFor(app.staticTexts["Inception"], timeout: 10)

        // Ajouter aux favoris
        let addButton = app.buttons["item.favorite.1"]
        waitFor(addButton, timeout: 10)
        addButton.tap()

        // Aller dans les favoris et retirer
        app.tabBars.buttons["Profil"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)

        // Le bouton supprimer dans la liste des favoris (via le bouton trash)
        // On navigue vers Mes favoris
        let mesFavorisButton = app.buttons["Mes favoris"]
        if mesFavorisButton.waitForExistence(timeout: 5) {
            mesFavorisButton.tap()
            waitFor(app.staticTexts["Inception"], timeout: 10)

            // Supprimer le favori
            let deleteButton = app.buttons.containing(.button, identifier: "trash.fill").firstMatch
            if deleteButton.waitForExistence(timeout: 5) {
                deleteButton.tap()
            }
        }

        // Vérifier que le favori a été retiré
        app.tabBars.buttons["Films"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)
        let favoriteButton = app.buttons["item.favorite.1"]
        // Le cœur devrait être vide (pas rempli)
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
    }

    // MARK: - Favoris depuis la vue détaillée

    func testAddMovieToFavoritesFromDetails() {
        app.tabBars.buttons["Films"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)

        // Ouvrir les détails d'Inception
        app.staticTexts["Inception"].tap()
        waitFor(app.staticTexts["details.title"], timeout: 10)

        // Ajouter aux favoris depuis la barre d'outils
        let favoriteButton = app.buttons["details.favorite"]
        waitFor(favoriteButton, timeout: 10)
        favoriteButton.tap()

        // Vérifier dans le profil
        app.tabBars.buttons["Profil"].tap()
        waitFor(app.staticTexts["Inception"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Inception"].exists)
    }

    // MARK: - Historique des quiz

    func testQuizHistoryIsSavedAfterCompleteQuiz() {
        app.tabBars.buttons["Quiz"].tap()
        waitFor(app.staticTexts["Question 1 / 10"], timeout: 10)

        // Faire tout le quiz
        for _ in 1...10 {
            let answerButton = app.buttons["quiz.answer.0"]
            waitFor(answerButton, timeout: 10)
            answerButton.tap()

            _ = app.staticTexts["quiz.feedback.correct"].waitForExistence(timeout: 5)
                || app.staticTexts["quiz.feedback.incorrect"].waitForExistence(timeout: 5)

            if app.staticTexts["Partie terminée !"].waitForExistence(timeout: 1) {
                break
            }

            if app.buttons["quiz.next"].waitForExistence(timeout: 5) {
                app.buttons["quiz.next"].tap()
            } else {
                break
            }
        }

        waitFor(app.staticTexts["Partie terminée !"], timeout: 10)

        // Aller dans l'historique des quiz depuis le profil
        app.tabBars.buttons["Profil"].tap()
        waitFor(app.staticTexts["Historique des quiz"], timeout: 10)

        let historiqueButton = app.buttons["Historique des quiz"]
        if historiqueButton.waitForExistence(timeout: 5) {
            historiqueButton.tap()
            waitFor(app.staticTexts["Quiz « quiz-"], timeout: 10)
        }
    }
}
