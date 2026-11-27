import SwiftUI

/// Vue de profil utilisateur : favoris, historique des quiz, gestion du compte.
struct ProfileView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var dataViewModel = UserDataViewModel()
    @State private var showingFavorites = false
    @State private var showingHistory = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if authViewModel.isAuthenticated {
                    ScrollView {
                        VStack(spacing: 24) {
                            // En-tête profil
                            VStack(spacing: 12) {
                                if let photoURL = authViewModel.user?.photoURL,
                                   let url = URL(string: photoURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.secondary)
                                }

                                Text(authViewModel.user?.displayName ?? "Utilisateur")
                                    .font(.title2.weight(.semibold))

                                Text(authViewModel.user?.email ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Label(authViewModel.user?.provider.rawValue.capitalized ?? "Inconnu", systemImage: "person.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.top)

                            // Statistiques rapides
                            HStack(spacing: 20) {
                                StatCard(title: "Favoris", value: "\(dataViewModel.favorites.count)", icon: "heart.fill", color: .red)
                                StatCard(title: "Quiz joués", value: "\(dataViewModel.quizHistory.count)", icon: "questionmark.circle", color: .blue)
                                if let last = dataViewModel.quizHistory.first {
                                    StatCard(title: "Dernier score", value: "\(last.score)/\(last.total)", icon: "trophy.fill", color: .orange)
                                }
                            }
                            .padding(.horizontal)

                            // Actions rapides
                            VStack(spacing: 12) {
                                Button(action: { showingFavorites = true }) {
                                    Label("Mes favoris", systemImage: "heart.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)

                                Button(action: { showingHistory = true }) {
                                    Label("Historique des quiz", systemImage: "clock.arrow.circlepath")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)

                                Divider()

                                Button(action: { showingDeleteConfirmation = true }) {
                                    Label("Supprimer mon compte", systemImage: "trash.fill")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)

                            // Déconnexion
                            Button(action: {
                                Task { await authViewModel.signOut() }
                            }) {
                                Label("Se déconnecter", systemImage: "arrow.right.to.circle")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .padding(.horizontal)
                            .padding(.bottom)

                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Non connecté",
                        systemImage: "person.fill.questionmark",
                        description: Text("Connectez-vous pour accéder à vos favoris, scores et historique.")
                    )
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if authViewModel.isAuthenticated {
                    await dataViewModel.loadUserData()
                }
            }
            .refreshable {
                if authViewModel.isAuthenticated {
                    await dataViewModel.loadUserData()
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesView()
            }
            .sheet(isPresented: $showingHistory) {
                QuizHistoryView()
            }
            .confirmationDialog("Supprimer le compte", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Supprimer définitivement", role: .destructive) {
                    Task {
                        let _ = await authViewModel.deleteAccount()
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action supprimera toutes vos données (favoris, scores, historique) et ne peut pas être annulée.")
            }
        }
    }
}

/// Carte de statistique simple.
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileView()
}
