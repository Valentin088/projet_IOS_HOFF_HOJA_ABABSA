import SwiftUI

/// L'application ne sert plus que d'hôte pour l'extension WidgetKit.
/// Toute l'expérience utilisateur se trouve désormais sur l'écran d'accueil.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "popcorn.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red)
                .accessibilityIdentifier("host.logo")

            Text("PopCornBox")
                .font(.largeTitle.bold())
                .accessibilityIdentifier("host.title")

            Text("Le catalogue est désormais disponible directement sur votre écran d'accueil.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityIdentifier("host.subtitle")

            VStack(alignment: .leading, spacing: 10) {
                InstructionRow(number: "1", text: "Quittez cette application et retournez sur l'écran d'accueil.")
                InstructionRow(number: "2", text: "Effectuez un appui long sur une zone vide.")
                InstructionRow(number: "3", text: "Touchez « + », recherchez PopCornBox et ajoutez le widget.")
            }
            .padding()
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("host.instructions")

            Text("Appui long sur le widget pour choisir Films ou Séries.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("host.widgetHint")
        }
        .padding()
        .accessibilityIdentifier("host.root")
    }
}

private struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.red, in: Circle())
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ContentView()
}
