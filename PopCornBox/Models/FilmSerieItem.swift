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

    // Champs utilisés par le quizz. Les valeurs par défaut de l'init gardent
    // les initialisations existantes compatibles.
    let backdropURL: URL?
    let releaseYear: Int?
    let genreIDs: [Int]
    let rating: Double?

    init(
        id: Int,
        kind: MediaType,
        title: String,
        snippet: String?,
        smallPosterURL: URL?,
        largePosterURL: URL?,
        url: URL?,
        backdropURL: URL? = nil,
        releaseYear: Int? = nil,
        genreIDs: [Int] = [],
        rating: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.snippet = snippet
        self.smallPosterURL = smallPosterURL
        self.largePosterURL = largePosterURL
        self.url = url
        self.backdropURL = backdropURL
        self.releaseYear = releaseYear
        self.genreIDs = genreIDs
        self.rating = rating
    }

    /// Un synopsis vide ou composé uniquement d'espaces ne doit pas être affiché.
    var hasSynopsis: Bool {
        guard let snippet else { return false }
        return !snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Texte de repli affiché par les vues de liste et de détail.
    var displaySynopsis: String {
        hasSynopsis ? snippet! : "Aucun synopsis disponible."
    }

    /// Titre non vide, même si l'API renvoie une chaîne vide.
    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sans titre" : title
    }
}
