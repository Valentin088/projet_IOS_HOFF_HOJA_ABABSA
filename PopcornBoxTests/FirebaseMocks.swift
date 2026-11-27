import Foundation
@testable import PopcornBox

/// Faux service d'authentification pour les tests unitaires.
@MainActor
final class MockAuthService: AuthServiceProtocol {
    var currentUserValue: UserProfile?
    var isAuthenticatedValue = false
    var userIdValue: String?

    var signInResult: AuthResult?
    var signUpResult: AuthResult?
    var signInGoogleResult: AuthResult?
    var signOutResult = true
    var resetPasswordResult = true
    var deleteAccountResult = true

    var signInCalls: [(email: String, password: String)] = []
    var signUpCalls: [(email: String, password: String, displayName: String?)] = []
    var signInGoogleCalls = 0
    var signOutCalls = 0
    var resetPasswordCalls: [String] = []
    var deleteAccountCalls = 0

    var currentUser: UserProfile? { currentUserValue }
    var isAuthenticated: Bool { isAuthenticatedValue }
    var userId: String? { userIdValue }

    func signIn(email: String, password: String) async -> AuthResult {
        signInCalls.append((email, password))
        return signInResult ?? .failure(AuthError.invalidCredentials)
    }

    func signUp(email: String, password: String, displayName: String?) async -> AuthResult {
        signUpCalls.append((email, password, displayName))
        return signUpResult ?? .failure(AuthError.emailAlreadyInUse)
    }

    func signInWithGoogle() async -> AuthResult {
        signInGoogleCalls += 1
        return signInGoogleResult ?? .failure(AuthError.invalidCredentials)
    }

    func signOut() async -> Bool {
        signOutCalls += 1
        return signOutResult
    }

    func resetPassword(email: String) async -> Bool {
        resetPasswordCalls.append(email)
        return resetPasswordResult
    }

    func deleteAccount() async -> Bool {
        deleteAccountCalls += 1
        return deleteAccountResult
    }
}

/// Faux service de données utilisateur pour les tests unitaires.
@MainActor
final class MockUserDataService: UserDataServiceProtocol {
    var currentUserIdValue: String?

    var favorites: [Favorite] = []
    var quizScores: [QuizScore] = []
    var quizHistory: [QuizHistoryEntry] = []

    var addFavoriteResult = true
    var removeFavoriteResult = true
    var saveQuizScoreResult = true
    var deleteAllUserDataResult = true

    var addFavoriteCalls: [FilmSerieItem] = []
    var removeFavoriteCalls: [(itemId: Int, kind: MediaType)] = []
    var saveQuizScoreCalls: [(score: Int, total: Int)] = []
    var deleteAllUserDataCalls = 0
    var isFavoriteCalls: [(itemId: Int, kind: MediaType)] = []
    var isFavoriteResults: [Bool] = []

    var currentUserId: String? { currentUserIdValue }

    func fetchFavorites() async -> [Favorite] { favorites }

    func addFavorite(_ item: FilmSerieItem) async -> Bool {
        addFavoriteCalls.append(item)
        return addFavoriteResult
    }

    func removeFavorite(itemId: Int, kind: MediaType) async -> Bool {
        removeFavoriteCalls.append((itemId, kind))
        return removeFavoriteResult
    }

    func isFavorite(itemId: Int, kind: MediaType) async -> Bool {
        isFavoriteCalls.append((itemId, kind))
        return isFavoriteResults.first ?? false
    }

    func saveQuizScore(score: Int, total: Int) async -> Bool {
        saveQuizScoreCalls.append((score, total))
        return saveQuizScoreResult
    }

    func fetchQuizHistory() async -> [QuizScore] { quizScores }

    func fetchRecentQuizEntries() async -> [QuizHistoryEntry] { quizHistory }

    func deleteAllUserData() async -> Bool {
        deleteAllUserDataCalls += 1
        return deleteAllUserDataResult
    }
}
