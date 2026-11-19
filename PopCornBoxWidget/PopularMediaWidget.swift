import WidgetKit
import SwiftUI

// MARK: - Timeline

struct PopularMediaEntry: TimelineEntry {
    let date: Date
    let items: [WidgetMediaItem]
    let mediaType: WidgetMediaType
    let isPlaceholder: Bool
}

struct PopularMediaProvider: AppIntentTimelineProvider {
    static let itemLimit = 6
    static let refreshIntervalHours = 3

    let client: any WidgetMediaProviding

    init(client: any WidgetMediaProviding = WidgetTMDBClient.shared) {
        self.client = client
    }

    /// Calcul isolé pour pouvoir vérifier la fréquence de rafraîchissement sans attendre 3 heures.
    func nextRefreshDate(from date: Date = Date()) -> Date {
        Calendar.current.date(
            byAdding: .hour,
            value: Self.refreshIntervalHours,
            to: date
        ) ?? date.addingTimeInterval(TimeInterval(Self.refreshIntervalHours * 3_600))
    }

    /// L'aperçu ne dépend pas du contexte : isolé pour être vérifiable en test unitaire.
    static func placeholderEntry() -> PopularMediaEntry {
        PopularMediaEntry(
            date: .now,
            items: WidgetMediaItem.samples(for: .movie),
            mediaType: .movie,
            isPlaceholder: true
        )
    }

    func placeholder(in context: Context) -> PopularMediaEntry {
        Self.placeholderEntry()
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PopularMediaEntry {
        await entry(for: configuration.mediaType)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PopularMediaEntry> {
        let entry = await entry(for: configuration.mediaType)
        return Timeline(entries: [entry], policy: .after(nextRefreshDate()))
    }

    /// Une panne réseau produit une entrée vide, jamais une exception ni un widget cassé.
    func entry(for mediaType: WidgetMediaType) async -> PopularMediaEntry {
        let items = (try? await client.popular(mediaType: mediaType, limit: Self.itemLimit)) ?? []
        return PopularMediaEntry(date: .now, items: items, mediaType: mediaType, isPlaceholder: false)
    }
}

// MARK: - Définition du widget

struct PopularMediaWidget: Widget {
    let kind = "PopCornBoxPopularMediaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: PopularMediaProvider()
        ) { entry in
            PopularMediaWidgetEntryView(entry: entry)
                .containerBackground(.red.gradient, for: .widget)
        }
        .configurationDisplayName("PopCornBox")
        .description("Les films et séries populaires du moment, signés TMDB.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Aperçus Xcode

#Preview(as: .systemSmall) {
    PopularMediaWidget()
} timeline: {
    PopularMediaEntry(
        date: .now,
        items: WidgetMediaItem.samples(for: .movie),
        mediaType: .movie,
        isPlaceholder: false
    )
}

#Preview(as: .systemMedium) {
    PopularMediaWidget()
} timeline: {
    PopularMediaEntry(
        date: .now,
        items: WidgetMediaItem.samples(for: .series),
        mediaType: .series,
        isPlaceholder: false
    )
}
