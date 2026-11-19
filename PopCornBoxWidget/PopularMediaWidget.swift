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
    func placeholder(in context: Context) -> PopularMediaEntry {
        PopularMediaEntry(
            date: .now,
            items: WidgetMediaItem.samples(for: .movie),
            mediaType: .movie,
            isPlaceholder: true
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> PopularMediaEntry {
        await entry(for: configuration.mediaType)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<PopularMediaEntry> {
        let entry = await entry(for: configuration.mediaType)
        let next = Calendar.current.date(byAdding: .hour, value: 3, to: Date())
            ?? Date().addingTimeInterval(3 * 60 * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func entry(for mediaType: WidgetMediaType) async -> PopularMediaEntry {
        let items = (try? await WidgetTMDBClient.shared.popular(mediaType: mediaType, limit: 6)) ?? []
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
