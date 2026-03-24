import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SearchViewModel()

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.selectedSection) {
            // Top navigation group (no header, matches Apple TV)
            Section {
                ForEach(SidebarSection.allCases.filter { $0.group == .navigation }) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .tag(section)
                }
            }

            // Library group
            Section("资料库") {
                ForEach(SidebarSection.allCases.filter { $0.group == .library }) { section in
                    Label(section.rawValue, systemImage: section.icon)
                        .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(
            text: $appState.searchQuery,
            placement: .sidebar,
            prompt: "搜索番剧或输入 CID"
        )
        .onSubmit(of: .search) {
            appState.selectedSection = .search
        }
        .onChange(of: appState.searchQuery) { _, _ in
            appState.selectedSection = .search
        }
        .navigationTitle("Bcrawler")
    }
}
