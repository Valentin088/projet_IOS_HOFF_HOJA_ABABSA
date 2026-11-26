import Foundation

// 1. Définition du type de média requis par le ViewModel et la Vue
enum MediaType: Equatable {
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
