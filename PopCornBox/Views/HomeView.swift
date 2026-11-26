import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image("logo-removebg-preview")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)

                Text("PopCornBox")
                    .font(.headline)

                Text("Les films et séries du moment, directement sur votre poignet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
