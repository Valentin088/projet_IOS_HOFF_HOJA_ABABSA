import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Découvrir") {
                    NavigationLink {
                        MoviesView()
                    } label: {
                        Label("Films populaires", systemImage: "film")
                    }
                    .accessibilityIdentifier("home.movies")

                    NavigationLink {
                        SeriesView()
                    } label: {
                        Label("Séries populaires", systemImage: "tv")
                    }
                    .accessibilityIdentifier("home.series")

                    NavigationLink {
                        QuizView()
                    } label: {
                        Label("Quiz", systemImage: "questionmark.circle.fill")
                    }
                    .accessibilityIdentifier("home.quiz")
                }

                Section("PopCornBox") {
                    NavigationLink {
                        HomeView()
                    } label: {
                        Label("À propos", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("PopCornBox")
            .listStyle(.carousel)
        }
    }
}

#Preview {
    ContentView()
}
