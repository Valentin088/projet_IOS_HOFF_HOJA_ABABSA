import SwiftUI

/// Vue des films et séries en favori de l'utilisateur.
struct FavoritesView: View {
    @StateObject private var dataViewModel = UserDataViewModel()
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Chargement des favoris...")
                } else if dataViewModel.favorites.isEmpty {
                    ContentUnavailableView(
                        "Aucun favori",
                        systemImage: "heart.slash",
                        description: Text("Ajoutez des films ou séries à vos favoris depuis les listes ou les fiches détaillées.")
                    )
                } else {
                    List {
                        ForEach(dataViewModel.favorites) { favorite in
                            FavoriteRow(favorite: favorite)
                        }
                        .onDelete(perform: deleteFavorites)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mes Favoris")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await dataViewModel.loadUserData()
                isLoading = false
            }
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let favorite = dataViewModel.favorites[index]
                let _ = await dataViewModel.dataService.removeFavorite(itemId: favorite.itemId, kind: favorite.kind)
            }
            await dataViewModel.loadUserData()
        }
    }
}

/// Ligne d'un favori avec titre, année, note et bouton de suppression.
private struct FavoriteRow: View {
    let favorite: Favorite
    @StateObject private var dataViewModel = UserDataViewModel()

    var body: some View {
        HStack(spacing: 12) {
            if let posterURLString = favorite.posterURL, let url = URL(string: posterURLString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: favorite.kind == .movie ? "film" : "tv")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: favorite.kind == .movie ? "film" : "tv")
                    .frame(width: 60, height: 90)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let year = favorite.releaseYear {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let rating = favorite.rating {
                        Text(String(format: "%.1f / 10", rating))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(favorite.kind == .movie ? "Film" : "Série")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2), in: Capsule())
                }
            }

            Spacer()

            Button(role: .destructive) {
                Task {
                    let _ = await dataViewModel.dataService.removeFavorite(itemId: favorite.itemId, kind: favorite.kind)
                    await dataViewModel.loadUserData()
                }
            } label: {
                Image(systemName: "trash.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesView()
}
