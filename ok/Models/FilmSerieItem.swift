import Foundation

// 1. Définition du type de média requis par le ViewModel et la Vue
enum MediaType: Equatable {
    case movie
    case series
}

// 2. Modèle unifié utilisé partout dans l'interface graphique
struct FilmSerieItem: Identifiable, Equatable {
    let id: Int
    let kind: MediaType
    let title: String
    let snippet: String?
    let smallPosterURL: URL?
    let largePosterURL: URL?
    let url: URL?

    // `backdropURL` est utilisé par le quizz : contrairement à l'affiche,
    // l'image de fond ne contient généralement pas le titre de l'œuvre.
    let backdropURL: URL?
    let releaseYear: Int?
    let genreIDs: [Int]
    let rating: Double?
}
