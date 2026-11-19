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

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "PopCornBox"
    static var description = IntentDescription("Choisissez d'afficher les films ou les séries populaires du moment.")

    @Parameter(title: "Contenu", default: .movie)
    var mediaType: WidgetMediaType
}
