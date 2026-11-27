import SwiftUI
@MainActor
struct FilmSerieItemView: View {
    let item: FilmSerieItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .accessibilityIdentifier("item.title")
            if let snippet = item.snippet {
                Text(snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 6)
        .accessibilityIdentifier("item.\(item.id)")
        .accessibilityLabel(Text(item.title))
    }
}

