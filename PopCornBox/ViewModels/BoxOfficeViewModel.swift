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
    private let client: TMDBClientProtocol
    private var requestID = 0

    convenience init(mediaType: MediaType) {
        self.init(mediaType: mediaType, client: TMDBClient())
    }

    init(mediaType: MediaType, client: TMDBClientProtocol) {
        self.mediaType = mediaType
        self.client = client
    }

    /// Charge les suggestions, ou recherche quand `query` contient du texte.
    func load(query: String? = nil, force: Bool = false) async {
        let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isSearch = !trimmedQuery.isEmpty

        // Évite les appels inutiles : suggestions déjà chargées ou chargement en cours.
        if !force && !isSearch && state == .loaded { return }
        if !force && state == .loading { return }

        let previousState = state
        requestID += 1
        let currentRequest = requestID
        state = .loading

        do {
            let results: [FilmSerieItem]
            if isSearch {
                results = try await client.search(mediaType: mediaType, query: trimmedQuery)
            } else {
                results = try await client.suggest(mediaType: mediaType)
            }

            // Une réponse ancienne ne doit jamais écraser une recherche plus récente.
            guard currentRequest == requestID else { return }
            items = results
            state = .loaded
        } catch is CancellationError {
            // L'utilisateur a continué à taper : on efface simplement ce chargement.
            guard currentRequest == requestID else { return }
            state = previousState == .loading ? .idle : previousState
        } catch {
            guard currentRequest == requestID else { return }
            state = .error(TMDBError.message(for: error))
        }
    }
}
