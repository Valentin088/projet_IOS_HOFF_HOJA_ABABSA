import Foundation

enum MediaType: String {
    case movie
    case series
}

struct FilmSerieItem: Identifiable, Hashable, Codable {
    var id: String { url?.absoluteString ?? title }

    let kind: MediaType
    let title: String
    let snippet: String?
    let url: URL?

    var kindLabel: String {
        kind == .movie ? "Film" : "Série"
    }

    init(kind: MediaType, title: String, snippet: String?, url: URL?) {
        self.kind = kind
        self.title = title
        self.snippet = snippet
        self.url = url
    }
}

