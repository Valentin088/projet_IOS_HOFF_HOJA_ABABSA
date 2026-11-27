import XCTest
@testable import PopcornBox

@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel(authService: MockAuthService) -> AuthViewModel {
        AuthViewModel(authService: authService)
    }

    // MARK: - Authentication status

    func testCheckAuthenticationStatusSetsShowAuthViewWhenNotAuthenticated() async {
        let authService = MockAuthService()
        authService.isAuthenticatedValue = false
        let viewModel = makeViewModel(authService: authService)

        await viewModel.checkAuthenticationStatus()

        XCTAssertTrue(viewModel.showAuthView)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.user)
    }

    func testCheckAuthenticationStatusSetsUserWhenAuthenticated() async {
        let authService = MockAuthService()
        let profile = UserProfile(uid: "abc123", email: "test@example.com", displayName: "Test User")
        authService.currentUserValue = profile
        authService.isAuthenticatedValue = true
        authService.userIdValue = "abc123"
        let viewModel = makeViewModel(authService: authService)

        await viewModel.checkAuthenticationStatus()

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertFalse(viewModel.showAuthView)
        XCTAssertEqual(viewModel.user?.uid, "abc123")
        XCTAssertEqual(viewModel.user?.email, "test@example.com")
    }

    // MARK: - Sign in

    func testSignInSuccessUpdatesState() async {
        let authService = MockAuthService()
        let profile = UserProfile(uid: "uid1", email: "user@example.com")
        authService.signInResult = .success(profile)
        let viewModel = makeViewModel(authService: authService)

        await viewModel.signIn(email: "user@example.com", password: "password123")

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.user?.uid, "uid1")
        XCTAssertFalse(viewModel.showAuthView)
        XCTAssertEqual(authService.signInCalls.count, 1)
        XCTAssertEqual(authService.signInCalls.first?.email, "user@example.com")
    }

    func testSignInFailureSetsError() async {
        let authService = MockAuthService()
        authService.signInResult = .failure(AuthError.invalidCredentials)
        let viewModel = makeViewModel(authService: authService)

        await viewModel.signIn(email: "user@example.com", password: "wrong")

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertTrue(viewModel.showAuthView)
        XCTAssertEqual(viewModel.errorMessage, AuthError.invalidCredentials.localizedDescription)
    }

    // MARK: - Sign up

    func testSignUpSuccessCreatesAccount() async {
        let authService = MockAuthService()
        let profile = UserProfile(uid: "newUid", email: "new@example.com", displayName: "New User")
        authService.signUpResult = .success(profile)
        let viewModel = makeViewModel(authService: authService)

        await viewModel.signUp(email: "new@example.com", password: "securePass", displayName: "New User")

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.user?.displayName, "New User")
        XCTAssertEqual(authService.signUpCalls.count, 1)
        XCTAssertEqual(authService.signUpCalls.first?.displayName, "New User")
    }

    func testSignUpEmailAlreadyInUseSetsError() async {
        let authService = MockAuthService()
        authService.signUpResult = .failure(AuthError.emailAlreadyInUse)
        let viewModel = makeViewModel(authService: authService)

        await viewModel.signUp(email: "existing@example.com", password: "pass", displayName: nil)

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, AuthError.emailAlreadyInUse.localizedDescription)
    }

    // MARK: - Sign in with Google

    func testSignInWithGoogleSuccess() async {
        let authService = MockAuthService()
        let profile = UserProfile(uid: "googleUid", email: "google@example.com", provider: .google)
        authService.signInGoogleResult = .success(profile)
        let viewModel = makeViewModel(authService: authService)

        await viewModel.signInWithGoogle()

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.user?.provider, .google)
        XCTAssertEqual(authService.signInGoogleCalls, 1)
    }

    // MARK: - Sign out

    func testSignOutResetsState() async {
        let authService = MockAuthService()
        authService.isAuthenticatedValue = true
        authService.currentUserValue = UserProfile(uid: "uid", email: "a@b.com")
        let viewModel = makeViewModel(authService: authService)
        viewModel.isAuthenticated = true
        viewModel.user = UserProfile(uid: "uid", email: "a@b.com")
        viewModel.showAuthView = false

        await viewModel.signOut()

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertTrue(viewModel.showAuthView)
        XCTAssertNil(viewModel.user)
        XCTAssertEqual(authService.signOutCalls, 1)
    }

    // MARK: - Delete account

    func testDeleteAccountResetsState() async {
        let authService = MockAuthService()
        authService.deleteAccountResult = true
        let viewModel = makeViewModel(authService: authService)
        viewModel.isAuthenticated = true
        viewModel.user = UserProfile(uid: "uid", email: "a@b.com")
        viewModel.showAuthView = false

        let success = await viewModel.deleteAccount()

        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.showAuthView)
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(authService.deleteAccountCalls, 1)
    }
}
