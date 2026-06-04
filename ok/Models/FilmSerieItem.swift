import Foundation

// 1. Définition du type de média requis par le ViewModel et la Vue
enum MediaType {
    case movie
    case series
}

// 2. Modèle unifié utilisé partout dans l'interface graphique
struct FilmSerieItem: Identifiable {
    let id: Int
    let kind: MediaType
    let title: String
    let snippet: String?
    let smallPosterURL: URL?
        let largePosterURL: URL?
    let url: URL?
}
