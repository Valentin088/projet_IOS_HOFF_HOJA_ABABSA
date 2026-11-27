import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct PopcornBoxApp: App {
    #if canImport(FirebaseCore)
    init() {
        FirebaseApp.configure()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
