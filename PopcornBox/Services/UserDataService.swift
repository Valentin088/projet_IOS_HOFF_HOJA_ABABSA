import Foundation
import FirebaseFirestore

/// Protocole d'accès aux données utilisateur : permet d'injecter un faux service dans les tests.
protocol UserDataServiceProtocol: AnyObject {
    var currentUserId: String? { get async }

    // MARK: - Favoris

    /// Récupère la liste des favoris de l'utilisateur connecté.
    func fetchFavorites() async -> [Favorite]

    /// Ajoute un film ou une série aux favoris.
    func addFavorite(_ item: FilmSerieItem) async -> Bool

    /// Retire un film ou une série des favoris.
    func removeFavorite(itemId: Int, kind: MediaType) async -> Bool

    /// Vérifie si un item est déjà en favori.
    func isFavorite(itemId: Int, kind: MediaType) async -> Bool

    // MARK: - Scores de quiz

    /// Sauvegarde le score d'un quiz terminé.
    func saveQuizScore(score: Int, total: Int) async -> Bool

    /// Récupère l'historique des scores de quiz (les plus récents d'abord).
    func fetchQuizHistory() async -> [QuizScore]

    // MARK: - Historique des quiz

    /// Récupère les derniers quiz effectués (limité à 10).
    func fetchRecentQuizEntries() async -> [QuizHistoryEntry]

    /// Supprime toutes les données de l'utilisateur (désinscription).
    func deleteAllUserData() async -> Bool
}

/// Implémentation Firestore de UserDataService.
@MainActor
final class UserDataService: UserDataServiceProtocol {
    static let shared = UserDataService()

    private let db = Firestore.firestore()
    private let auth: AuthServiceProtocol

    init(auth: AuthServiceProtocol = AuthService.shared) {
        self.auth = auth
    }

    var currentUserId: String? {
        get async { await auth.userId }
    }

    // MARK: - Favoris

    func fetchFavorites() async -> [Favorite] {
        guard let userId = await currentUserId else { return [] }
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("favorites")
                .order(by: "addedAt", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Favorite.self) }
        } catch {
            return []
        }
    }

    func addFavorite(_ item: FilmSerieItem) async -> Bool {
        guard let userId = await currentUserId else { return false }
        do {
            let favorite = Favorite(
                userId: userId,
                itemId: item.id,
                kind: item.kind,
                title: item.title,
                snippet: item.snippet,
                posterURL: item.smallPosterURL?.absoluteString,
                backdropURL: item.backdropURL?.absoluteString,
                releaseYear: item.releaseYear,
                rating: item.rating
            )
            try await db.collection("users")
                .document(userId)
                .collection("favorites")
                .document(favorite.id)
                .setData(from: favorite)
            return true
        } catch {
            return false
        }
    }

    func removeFavorite(itemId: Int, kind: MediaType) async -> Bool {
        guard let userId = await currentUserId else { return false }
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("favorites")
                .whereField("itemId", isEqualTo: itemId)
                .whereField("kind", isEqualTo: kind.rawValue)
                .getDocuments()
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
            return true
        } catch {
            return false
        }
    }

    func isFavorite(itemId: Int, kind: MediaType) async -> Bool {
        guard let userId = await currentUserId else { return false }
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("favorites")
                .whereField("itemId", isEqualTo: itemId)
                .whereField("kind", isEqualTo: kind.rawValue)
                .limit(to: 1)
                .getDocuments()
            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Scores de quiz

    func saveQuizScore(score: Int, total: Int) async -> Bool {
        guard let userId = await currentUserId else { return false }
        do {
            let quizScore = QuizScore(userId: userId, score: score, total: total)
            let entry = QuizHistoryEntry(
                userId: userId,
                quizId: quizScore.id,
                score: score,
                total: total
            )

            // Écriture en batch pour atomicité
            let batch = db.batch()
            let scoreRef = db.collection("users")
                .document(userId)
                .collection("quizScores")
                .document(quizScore.id)
            let historyRef = db.collection("users")
                .document(userId)
                .collection("quizHistory")
                .document(entry.id)

            batch.setData(from: quizScore, forDocument: scoreRef)
            batch.setData(from: entry, forDocument: historyRef)
            try await batch.commit()
            return true
        } catch {
            return false
        }
    }

    func fetchQuizHistory() async -> [QuizScore] {
        guard let userId = await currentUserId else { return [] }
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("quizScores")
                .order(by: "completedAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: QuizScore.self) }
        } catch {
            return []
        }
    }

    func fetchRecentQuizEntries() async -> [QuizHistoryEntry] {
        guard let userId = await currentUserId else { return [] }
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("quizHistory")
                .order(by: "completedAt", descending: true)
                .limit(to: 10)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: QuizHistoryEntry.self) }
        } catch {
            return []
        }
    }

    func deleteAllUserData() async -> Bool {
        guard let userId = await currentUserId else { return false }
        do {
            // Supprimer les collections de sous-documents
            let collections = ["favorites", "quizScores", "quizHistory"]
            for collection in collections {
                let snapshot = try await db.collection("users")
                    .document(userId)
                    .collection(collection)
                    .getDocuments()
                for doc in snapshot.documents {
                    try await doc.reference.delete()
                }
            }
            // Supprimer le document utilisateur
            try await db.collection("users").document(userId).delete()
            return true
        } catch {
            return false
        }
    }
}

/// Erreurs de données utilisateur.
enum UserDataError: LocalizedError {
    case notAuthenticated
    case saveFailed
    case fetchFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Utilisateur non connecté."
        case .saveFailed: return "Échec de l'enregistrement."
        case .fetchFailed: return "Échec de la récupération des données."
        case .deleteFailed: return "Échec de la suppression des données."
        }
    }
}
