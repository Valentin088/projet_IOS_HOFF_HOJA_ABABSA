import Foundation
import FirebaseFirestore

/// Profil utilisateur stocké dans Firestore (collection `users`).
struct UserProfile: Codable, Equatable {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let isAnonymous: Bool
    let provider: AuthProvider
    let createdAt: Date
    var updatedAt: Date

    enum AuthProvider: String, Codable {
        case email
        case google
        case anonymous
    }

    init(
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: String? = nil,
        isAnonymous: Bool = false,
        provider: AuthProvider = .email,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isAnonymous = isAnonymous
        self.provider = provider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Film ou série ajouté aux favoris par un utilisateur.
struct Favorite: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let itemId: Int
    let kind: MediaType
    let title: String
    let snippet: String?
    let posterURL: String?
    let backdropURL: String?
    let releaseYear: Int?
    let rating: Double?
    let addedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        itemId: Int,
        kind: MediaType,
        title: String,
        snippet: String? = nil,
        posterURL: String? = nil,
        backdropURL: String? = nil,
        releaseYear: Int? = nil,
        rating: Double? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.itemId = itemId
        self.kind = kind
        self.title = title
        self.snippet = snippet
        self.posterURL = posterURL
        self.backdropURL = backdropURL
        self.releaseYear = releaseYear
        self.rating = rating
        self.addedAt = addedAt
    }
}

/// Résultat d'un quiz effectué par un utilisateur.
struct QuizScore: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let score: Int
    let total: Int
    let percentage: Double
    let completedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        score: Int,
        total: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.score = score
        self.total = total
        self.percentage = total > 0 ? Double(score) / Double(total) * 100 : 0
        self.completedAt = completedAt
    }
}

/// Entrée de l'historique des quiz récents d'un utilisateur.
struct QuizHistoryEntry: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let quizId: String
    let score: Int
    let total: Int
    let completedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        quizId: String,
        score: Int,
        total: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.quizId = quizId
        self.score = score
        self.total = total
        self.completedAt = completedAt
    }
}
