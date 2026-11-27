import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack() {
                Image("logo-removebg-preview")
                    .frame(width: 300, height: 300)
                    .accessibilityIdentifier("home.logo")
                
                Text("Bienvenue sur PopCornBox")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("home.welcome")
                
                Text("Découvrez les films et séries du moment grâce à notre catalogue mis à jour en temps réel.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Accueil")
        }
    }
} 
