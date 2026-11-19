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

                    NavigationLink {
                        SeriesView()
                    } label: {
                        Label("Séries populaires", systemImage: "tv")
                    }
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
