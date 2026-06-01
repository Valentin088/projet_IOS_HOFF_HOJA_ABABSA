import SwiftUI

struct HomeView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: MoviesView()) {
                    Label("Films - Box Office", systemImage: "film")
                }
                NavigationLink(destination: SeriesView()) {
                    Label("Séries - Box Office", systemImage: "tv")
                }
            } header: {
                Text("Suggestions du moment")
                    .font(.headline)
            }
        }
        .navigationTitle("Accueil")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}

