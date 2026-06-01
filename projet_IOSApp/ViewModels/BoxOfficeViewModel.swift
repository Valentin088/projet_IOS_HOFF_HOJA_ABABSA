import Foundation

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
    private let client: TraktClient

    init(mediaType: MediaType, client: TraktClient = TraktClient()) {
        self.mediaType = mediaType
        self.client = client
    }

    func load(force: Bool = false) async {
        if state == .loading { return }
        if !force, state == .loaded { return }

        state = .loading
        do {
            let results = try await client.suggest(mediaType: mediaType)
            items = results
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}


