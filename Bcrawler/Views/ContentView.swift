import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SidebarView()
        } detail: {
            switch appState.selectedSection {
            case .search:
                SearchContentView()
            case .recentExports:
                RecentExportsView()
            case .favorites:
                FavoritesView()
            case .settings:
                SettingsView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
