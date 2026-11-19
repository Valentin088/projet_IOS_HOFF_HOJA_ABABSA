import SwiftUI

struct DetailsView: View {
    let item: FilmSerieItem

    private let client = TMDBClient()
    @State private var cast: [Cast] = []
    @State private var isLoadingCast = false
    @State private var castError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                poster

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Synopsis")
                        .font(.headline)
                        .foregroundStyle(.red)

                    if let snippet = item.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.body)
                    } else {
                        Text("Aucun synopsis disponible.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Acteurs")
                        .font(.headline)
                        .foregroundStyle(.red)

                    castContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical)
        }
        .navigationTitle("Détails")
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
        }
    }

    @ViewBuilder
    private var poster: some View {
        AsyncImage(url: item.largePosterURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 120)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            case .failure:
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(height: 120)
            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var castContent: some View {
        if isLoadingCast {
            ProgressView("Chargement des acteurs...")
        } else if let castError {
            Text(castError)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if cast.isEmpty {
            Text("Aucun acteur trouvé.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(cast.prefix(8)) { actor in
                HStack(alignment: .top, spacing: 8) {
                    actorPhoto(for: actor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(actor.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(actor.character)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actorPhoto(for actor: Cast) -> some View {
        if let url = actor.profileURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 32, height: 48)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                case .failure:
                    actorPhotoPlaceholder
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 32, height: 48)
        } else {
            actorPhotoPlaceholder
                .frame(width: 32, height: 48)
        }
    }

    private var actorPhotoPlaceholder: some View {
        Image(systemName: "person.crop.rectangle")
            .foregroundStyle(.secondary)
    }
}
