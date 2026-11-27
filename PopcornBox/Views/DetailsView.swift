import SwiftUI

struct DetailsView: View {
    let item: FilmSerieItem
    
    // ✅ NOUVEAU : Propriétés pour les acteurs
    private let client: TMDBProviding
    @StateObject private var dataViewModel = UserDataViewModel()
    @State private var cast: [Cast] = []
    @State private var isLoadingCast = false
    @State private var castError: String?
    @State private var isFavorite = false
    
    init(item: FilmSerieItem) {
        self.item = item
        self.client = UITesting.isEnabled ? UITesting.Client() : TMDBClient()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: item.largePosterURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 10)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 400)
                .padding(.top)
                .accessibilityIdentifier("details.poster")
                
                VStack(alignment: .leading, spacing: 15) {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("details.title")
                    
                    Text("Synopsis")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    if let snippet = item.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.body)
                            .lineSpacing(5)
                            .accessibilityIdentifier("details.synopsis")
                    } else {
                        Text("Aucun synopsis disponible.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("details.synopsis")
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Acteurs")
                        .font(.headline)
                        .foregroundColor(.red)

                    if isLoadingCast {
                        ProgressView("Chargement des acteurs...")
                            .accessibilityIdentifier("details.loading.cast")
                    } else if let castError {
                        Text(castError)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("details.error.cast")
                    } else if cast.isEmpty {
                        Text("Aucun acteur trouvé.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(cast.prefix(10)) { actor in
                                HStack(alignment: .top, spacing: 12) {
                                    if let url = actor.profileURL {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 44, height: 66)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 44, height: 66)
                                                    .clipped()
                                                    .cornerRadius(6)
                                            case .failure:
                                                Image(systemName: "person.crop.rectangle")
                                                    .frame(width: 44, height: 66)
                                                    .foregroundStyle(.secondary)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.crop.rectangle")
                                            .frame(width: 44, height: 66)
                                            .foregroundStyle(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(actor.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .accessibilityIdentifier("details.cast.name")
                                        Text(actor.character)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 0)
            }
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await dataViewModel.toggleFavorite(item)
                        isFavorite = await dataViewModel.dataService.isFavorite(itemId: item.id, kind: item.kind)
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                }
                .accessibilityIdentifier("details.favorite")
            }
        }
        .task {
            guard !isLoadingCast else { return }
            isLoadingCast = true
            castError = nil
            do {
                cast = try await client.fetchCast(mediaType: item.kind, id: item.id)
            } catch {
                castError = error.localizedDescription
            }
            isLoadingCast = false
            
            // Vérifier si l'item est déjà en favori
            isFavorite = await dataViewModel.dataService.isFavorite(itemId: item.id, kind: item.kind)
        }
    }
}
