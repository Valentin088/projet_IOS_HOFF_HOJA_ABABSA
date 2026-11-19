import SwiftUI

struct ContentView: View {
    var body: some View {
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
        }
        .tint(.red) // Couleur du thème PopCornBox
    }
}
