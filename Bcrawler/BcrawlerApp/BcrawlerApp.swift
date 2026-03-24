import SwiftUI

@main
struct BcrawlerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1080, height: 720)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
