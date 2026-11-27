import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image("logo-removebg-preview")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .accessibilityIdentifier("home.logo")

                Text("PopCornBox")
                    .font(.headline)
                    .accessibilityIdentifier("home.title")

                Text("Les films et séries du moment, directement sur votre poignet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("home.subtitle")
            }
            .padding()
        }
        .navigationTitle("À propos")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
