import SwiftUI

/// Vue d'authentification : connexion, inscription, connexion Google.
struct AuthenticationView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isResettingPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword, displayName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "popcorn.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)

                    Text("PopCornBox")
                        .font(.largeTitle.weight(.bold))

                    Text(isSignUp ? "Créer un compte" : "Se connecter")
                        .font(.title2.weight(.semibold))

                    VStack(spacing: 12) {
                        if isSignUp {
                            TextField("Nom d'affichage", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .displayName)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        SecureField("Mot de passe", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .password)
                            .textContentType(isSignUp ? .newPassword : .password)

                        if isSignUp {
                            SecureField("Confirmer le mot de passe", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .confirmPassword)
                                .textContentType(.newPassword)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: handleAuth) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(isSignUp ? "Créer le compte" : "Se connecter")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(viewModel.isLoading || !isFormValid)

                    Button(isSignUp ? "Déjà un compte ? Connectez-vous" : "Pas de compte ? Créez-en un") {
                        isSignUp.toggle()
                        viewModel.clearError()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)

                    Divider()

                    Button(action: {
                        Task { await viewModel.signInWithGoogle() }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Se connecter avec Google")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.isLoading)

                    Button("Mot de passe oublié ?") {
                        isResettingPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(isSignUp ? "Inscription" : "Connexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        // Notifier le parent pour fermer la vue d'auth
                    }
                }
            }
            .alert("Réinitialiser le mot de passe", isPresented: $isResettingPassword) {
                TextField("Email", text: $email)
                Button("Annuler", role: .cancel) {}
                Button("Envoyer") {
                    Task {
                        await viewModel.resetPassword(email: email)
                    }
                }
            } message: {
                Text("Entrez votre adresse email pour recevoir un lien de réinitialisation.")
            }
            .onAppear {
                Task {
                    await viewModel.checkAuthenticationStatus()
                }
            }
        }
    }

    private var isFormValid: Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }
        if isSignUp {
            return !displayName.isEmpty && password == confirmPassword && password.count >= 6
        }
        return true
    }

    private func handleAuth() {
        Task {
            if isSignUp {
                await viewModel.signUp(email: email, password: password, displayName: displayName.isEmpty ? nil : displayName)
            } else {
                await viewModel.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
