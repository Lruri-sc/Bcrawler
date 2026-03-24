import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            List(selection: $appState.selectedSection) {
                Section {
                    ForEach(SidebarSection.allCases.filter { $0.group == .navigation }) { section in
                        Label(section.rawValue, systemImage: section.icon)
                            .tag(section)
                    }
                }

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

            if appState.isExporting {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(appState.exportStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    ProgressView(value: appState.exportProgress)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Bcrawler")
    }
}
