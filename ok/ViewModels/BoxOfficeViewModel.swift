import Foundation
import Combine

@MainActor
final class BoxOfficeViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    @Published private(set) var items: [FilmSerieItem] = []
    @Published private(set) var state: State = .idle

    private let mediaType: MediaType
    private let client: TMDBClient

    init(mediaType: MediaType, client: TMDBClient = TMDBClient()) {
        self.mediaType = mediaType
        self.client = client
    }

    // On ajoute le paramètre 'query' ici
    func load(query: String? = nil, force: Bool = false) async {
        // Permet d'éviter de relancer un chargement si on est déjà en train de chercher/charger
        if state == .loading && !force { return }
        
        state = .loading
        do {
            // Logique : Si on a du texte dans 'query', on recherche. Sinon, on charge les suggestions.
            if let query = query, !query.isEmpty {
                let results = try await client.search(mediaType: mediaType, query: query)
                items = results
            } else {
                if !force, state == .loaded { return } // Évite de recharger les suggestions si déjà chargées
                let results = try await client.suggest(mediaType: mediaType)
                items = results
            }
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
