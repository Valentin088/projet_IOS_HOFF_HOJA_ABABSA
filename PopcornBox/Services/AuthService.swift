import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import UIKit

/// Résultat d'une opération d'authentification.
enum AuthResult {
    case success(UserProfile)
    case failure(Error)
}

/// Protocole d'authentification : permet d'injecter un faux service dans les tests.
protocol AuthServiceProtocol: AnyObject {
    var currentUser: UserProfile? { get async }
    var isAuthenticated: Bool { get async }
    var userId: String? { get async }

    /// Connexion avec email et mot de passe.
    func signIn(email: String, password: String) async -> AuthResult

    /// Création de compte avec email et mot de passe (sans Google).
    func signUp(email: String, password: String, displayName: String?) async -> AuthResult

    /// Connexion avec Google.
    func signInWithGoogle() async -> AuthResult

    /// Déconnexion.
    func signOut() async -> Bool

    /// Réinitialisation du mot de passe.
    func resetPassword(email: String) async -> Bool

    /// Suppression du compte.
    func deleteAccount() async -> Bool
}

/// Implémentation Firebase de AuthService.
@MainActor
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    var currentUser: UserProfile? {
        get async {
            guard let firebaseUser = auth.currentUser else { return nil }
            return await profile(from: firebaseUser)
        }
    }

    var isAuthenticated: Bool {
        auth.currentUser != nil
    }

    var userId: String? {
        auth.currentUser?.uid
    }

    func signIn(email: String, password: String) async -> AuthResult {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return .success(await profile(from: result.user))
        } catch {
            return .failure(error)
        }
    }

    func signUp(email: String, password: String, displayName: String?) async -> AuthResult {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            try await result.user.sendEmailVerification()
            if let displayName, !displayName.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
            let profile = await profile(from: result.user)
            try await db.collection("users").document(result.user.uid).setData(profile.firestoreData)
            return .success(profile)
        } catch {
            return .failure(error)
        }
    }

    func signInWithGoogle() async -> AuthResult {
        guard let presentingVC = rootViewController() else {
            return .failure(AuthError.noRootViewController)
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
            guard let idToken = result.user.idToken?.tokenString else {
                return .failure(AuthError.missingIDToken)
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: result.user.accessToken.tokenString)
            let authResult = try await auth.signIn(with: credential)
            let profile = await profile(from: authResult.user)

            try await db.collection("users").document(authResult.user.uid).setData(profile.firestoreData, merge: true)

            return .success(profile)
        } catch {
            return .failure(error)
        }
    }

    func signOut() async -> Bool {
        do {
            try auth.signOut()
            try GIDSignIn.sharedInstance.signOut()
            return true
        } catch {
            return false
        }
    }

    func resetPassword(email: String) async -> Bool {
        do {
            try await auth.sendPasswordReset(withEmail: email)
            return true
        } catch {
            return false
        }
    }

    func deleteAccount() async -> Bool {
        guard let user = auth.currentUser else { return false }
        do {
            try await db.collection("users").document(user.uid).delete()
            try await user.delete()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helpers privés

    private func profile(from firebaseUser: User) async -> UserProfile {
        let doc = try? await db.collection("users").document(firebaseUser.uid).getDocument()
        let stored = try? doc?.data(as: UserProfile.self)
        return stored ?? UserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString,
            isAnonymous: firebaseUser.isAnonymous,
            provider: firebaseUser.providerData.first(where: { $0.providerID == "google.com" }) != nil ? .google : .email,
            createdAt: firebaseUser.metadata.creationDate ?? Date(),
            updatedAt: Date()
        )
    }

    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController
    }
}

/// Erreurs d'authentification.
enum AuthError: LocalizedError {
    case noRootViewController
    case missingIDToken
    case userNotFound
    case invalidCredentials
    case accountAlreadyExists
    case weakPassword
    case emailAlreadyInUse

    var errorDescription: String? {
        switch self {
        case .noRootViewController: return "Impossible de trouver la vue principale."
        case .missingIDToken: return "Jeton d'identité Google manquant."
        case .userNotFound: return "Utilisateur introuvable."
        case .invalidCredentials: return "Identifiants invalides."
        case .accountAlreadyExists: return "Ce compte existe déjà."
        case .weakPassword: return "Le mot de passe est trop faible."
        case .emailAlreadyInUse: return "Cette adresse email est déjà utilisée."
        }
    }
}

extension UserProfile {
    var firestoreData: [String: Any] {
        [
            "uid": uid,
            "email": email as Any,
            "displayName": displayName as Any,
            "photoURL": photoURL as Any,
            "isAnonymous": isAnonymous,
            "provider": provider.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
        ]
    }
}
