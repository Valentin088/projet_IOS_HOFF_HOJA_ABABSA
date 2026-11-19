import SwiftUI
import WidgetKit

struct PopularMediaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PopularMediaEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Petit widget

private struct SmallWidgetView: View {
    let entry: PopularMediaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            if let first = entry.items.first {
                Link(destination: first.url ?? URL(string: "https://www.themoviedb.org")!) {
                    HStack(alignment: .top, spacing: 8) {
                        PosterThumb(item: first, size: CGSize(width: 52, height: 78))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(first.title)
                                .font(.headline)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                            Text("N°1 du moment")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
            } else {
                emptyState
            }

            Spacer(minLength: 0)

            Text("PopCornBox")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(12)
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: entry.mediaType == .movie ? "film.fill" : "tv.fill")
            Text(entry.mediaType == .movie ? "Top films" : "Top séries")
                .font(.caption.weight(.bold))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "popcorn.fill")
                .font(.title2)
            Text("Ouvrez PopCornBox pour charger les tendances.")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Widget moyen

private struct MediumWidgetView: View {
    let entry: PopularMediaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(
                    entry.mediaType == .movie ? "Films populaires" : "Séries populaires",
                    systemImage: entry.mediaType == .movie ? "film.fill" : "tv.fill"
                )
                .font(.headline)
                Spacer()
                Text("TMDB")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }

            if entry.items.isEmpty {
                emptyState
            } else {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(entry.items.prefix(3)) { item in
                        Link(destination: item.url ?? URL(string: "https://www.themoviedb.org")!) {
                            VStack(alignment: .leading, spacing: 4) {
                                PosterThumb(item: item, size: CGSize(width: 62, height: 93))
                                Text(item.title)
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(height: 28, alignment: .top)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(14)
    }

    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "popcorn.fill")
            Text("Aucune donnée. Ouvrez PopCornBox puis réessayez.")
                .font(.caption)
        }
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity, minHeight: 90)
    }
}

// MARK: - Grand widget

private struct LargeWidgetView: View {
    let entry: PopularMediaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    entry.mediaType == .movie ? "Top films" : "Top séries",
                    systemImage: entry.mediaType == .movie ? "film.fill" : "tv.fill"
                )
                .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: "popcorn.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }

            if entry.items.isEmpty {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                    Text("Impossible de charger les tendances.")
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.items.prefix(6)) { item in
                        Link(destination: item.url ?? URL(string: "https://www.themoviedb.org")!) {
                            HStack(spacing: 10) {
                                PosterThumb(item: item, size: CGSize(width: 38, height: 57))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Text(item.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Affiche

private struct PosterThumb: View {
    let item: WidgetMediaItem
    let size: CGSize

    var body: some View {
        Group {
            if let data = item.posterData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.white.opacity(0.14)
                    Image(systemName: "popcorn")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(.white.opacity(0.18), lineWidth: 0.5)
        }
    }
}
