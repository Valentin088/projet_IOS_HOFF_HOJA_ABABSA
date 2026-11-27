import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.showAuthView {
                AuthenticationView()
            } else {
                mainTabView
            }
        }
        .task {
            await authViewModel.checkAuthenticationStatus()
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }

            MoviesView()
                .tabItem {
                    Label("Films", systemImage: "film")
                }

            SeriesView()
                .tabItem {
                    Label("Séries", systemImage: "tv")
                }

            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
        }
        .tint(.red)
    }
}

#Preview {
    ContentView()
}
