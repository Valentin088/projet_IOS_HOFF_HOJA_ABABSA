import AppIntents

/// Type de média proposé dans la configuration du widget (appui long → Modifier le widget).
enum WidgetMediaType: String, AppEnum {
    case movie
    case series

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Type de média"

    static var caseDisplayRepresentations: [WidgetMediaType: DisplayRepresentation] = [
        .movie: DisplayRepresentation(title: "Films"),
        .series: DisplayRepresentation(title: "Séries")
    ]
}

extension WidgetMediaType {
    var symbolName: String { self == .movie ? "film.fill" : "tv.fill" }
    var headline: String { self == .movie ? "Top films" : "Top séries" }
    var longHeadline: String { self == .movie ? "Films populaires" : "Séries populaires" }
    var subtitle: String { self == .movie ? "Film populaire" : "Série populaire" }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "PopCornBox"
    static var description = IntentDescription("Choisissez d'afficher les films ou les séries populaires du moment.")

    @Parameter(title: "Contenu", default: .movie)
    var mediaType: WidgetMediaType
}
