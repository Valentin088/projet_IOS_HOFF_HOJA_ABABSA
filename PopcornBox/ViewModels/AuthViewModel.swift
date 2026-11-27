import Foundation
import SwiftUI

/// ViewModel gérant l'état d'authentification de l'application.
@MainActor
final class AuthViewModel: ObservableObject {
    private let authService: AuthServiceProtocol

    @Published private(set) var user: UserProfile?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var showAuthView = false

    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }

    func checkAuthenticationStatus() async {
        isLoading = true
        defer { isLoading = false }

        // En mode tests UI, simuler un utilisateur déjà connecté
        // pour permettre les tests de favoris sans vraie authentification Firebase.
        if UITesting.isEnabled {
            self.user = UserProfile(
                uid: "uitest_user",
                email: "uitest@example.com",
                displayName: "Utilisateur Test",
                provider: .email
            )
            self.isAuthenticated = true
            self.showAuthView = false
            return
        }

        isAuthenticated = await authService.isAuthenticated
        user = await authService.currentUser
        showAuthView = !isAuthenticated
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = await authService.signIn(email: email, password: password)
        switch result {
        case .success(let profile):
            user = profile
            isAuthenticated = true
            showAuthView = false
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String, displayName: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = await authService.signUp(email: email, password: password, displayName: displayName)
        switch result {
        case .success(let profile):
            user = profile
            isAuthenticated = true
            showAuthView = false
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = await authService.signInWithGoogle()
        switch result {
        case .success(let profile):
            user = profile
            isAuthenticated = true
            showAuthView = false
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        let success = await authService.signOut()
        if success {
            user = nil
            isAuthenticated = false
            showAuthView = true
        } else {
            errorMessage = "Impossible de se déconnecter."
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let success = await authService.resetPassword(email: email)
        if !success {
            errorMessage = "Impossible d'envoyer l'email de réinitialisation."
        }
    }

    func deleteAccount() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let success = await authService.deleteAccount()
        if success {
            user = nil
            isAuthenticated = false
            showAuthView = true
        } else {
            errorMessage = "Impossible de supprimer le compte."
        }
        return success
    }

    func clearError() {
        errorMessage = nil
    }
}

/// ViewModel gérant les données utilisateur (favoris, scores, historique).
@MainActor
final class UserDataViewModel: ObservableObject {
    private let dataService: UserDataServiceProtocol

    @Published private(set) var favorites: [Favorite] = []
    @Published private(set) var quizHistory: [QuizScore] = []
    @Published private(set) var recentQuizEntries: [QuizHistoryEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // Données simulées pour les tests UI (mode -UITesting)
    private static var mockFavorites: [Favorite] = []
    private static var mockQuizHistory: [QuizScore] = []
    private static var mockRecentQuiz: [QuizHistoryEntry] = []

    init(dataService: UserDataServiceProtocol = UserDataService.shared) {
        self.dataService = dataService
    }

    func loadUserData() async {
        // En mode tests UI, utiliser des données simulées en mémoire
        if UITesting.isEnabled {
            self.favorites = Self.mockFavorites
            self.quizHistory = Self.mockQuizHistory
            self.recentQuizEntries = Self.mockRecentQuiz
            self.isLoading = false
            return
        }

        guard await dataService.currentUserId != nil else {
            errorMessage = "Utilisateur non connecté."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let favs = dataService.fetchFavorites()
        async let scores = dataService.fetchQuizHistory()
        async let history = dataService.fetchRecentQuizEntries()

        self.favorites = await favs
        self.quizHistory = await scores
        self.recentQuizEntries = await history
    }

    func toggleFavorite(_ item: FilmSerieItem) async {
        // En mode tests UI, gérer les favoris en mémoire
        if UITesting.isEnabled {
            isLoading = true
            defer { isLoading = false }

            let isFav = Self.mockFavorites.contains { $0.itemId == item.id && $0.kind == item.kind }
            if isFav {
                Self.mockFavorites.removeAll { $0.itemId == item.id && $0.kind == item.kind }
                favorites.removeAll { $0.itemId == item.id && $0.kind == item.kind }
            } else {
                let newFavorite = Favorite(
                    userId: "uitest_user",
                    itemId: item.id,
                    kind: item.kind,
                    title: item.title,
                    snippet: item.snippet,
                    posterURL: item.smallPosterURL?.absoluteString,
                    backdropURL: item.backdropURL?.absoluteString,
                    releaseYear: item.releaseYear,
                    rating: item.rating
                )
                Self.mockFavorites.append(newFavorite)
                await loadUserData()
            }
            return
        }

        isLoading = true
        defer { isLoading = false }

        let isFav = await dataService.isFavorite(itemId: item.id, kind: item.kind)

        if isFav {
            let success = await dataService.removeFavorite(itemId: item.id, kind: item.kind)
            if success {
                favorites.removeAll { $0.itemId == item.id && $0.kind == item.kind }
            } else {
                errorMessage = "Impossible de retirer des favoris."
            }
        } else {
            let success = await dataService.addFavorite(item)
            if success {
                await loadUserData()
            } else {
                errorMessage = "Impossible d'ajouter aux favoris."
            }
        }
    }

    func isItemFavorite(_ item: FilmSerieItem) async -> Bool {
        if UITesting.isEnabled {
            return Self.mockFavorites.contains { $0.itemId == item.id && $0.kind == item.kind }
        }
        return await dataService.isFavorite(itemId: item.id, kind: item.kind)
    }

    func saveQuizResult(score: Int, total: Int) async {
        // En mode tests UI, sauvegarder en mémoire
        if UITesting.isEnabled {
            isLoading = true
            defer { isLoading = false }

            let newScore = QuizScore(userId: "uitest_user", score: score, total: total)
            Self.mockQuizHistory.append(newScore)
            Self.mockRecentQuiz.append(QuizHistoryEntry(
                userId: "uitest_user",
                quizId: newScore.id,
                score: score,
                total: total
            ))
            await loadUserData()
            return
        }

        isLoading = true
        defer { isLoading = false }

        let success = await dataService.saveQuizScore(score: score, total: total)
        if success {
            await loadUserData()
        } else {
            errorMessage = "Impossible d'enregistrer le score."
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
