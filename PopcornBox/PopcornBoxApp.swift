import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct PopcornBoxApp: App {
    #if canImport(FirebaseCore)
    init() {
        // FirebaseApp.configure() plante si GoogleService-Info.plist est absent.
        // Le fichier fourni contient des valeurs factices : remplace-le par ta vraie config Firebase.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
