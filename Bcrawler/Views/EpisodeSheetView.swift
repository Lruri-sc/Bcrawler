import SwiftUI

struct EpisodeSheetView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let bangumi = appState.selectedBangumi {
                    BangumiHeaderView(bangumi: bangumi)
                }

                Divider()

                if appState.isLoadingEpisodes {
                    Spacer()
                    ProgressView("加载集数...")
                    Spacer()
                } else {
                    EpisodeListView()
                }

                Divider()

                ExportBarView(viewModel: viewModel, dismissSheet: dismiss)
            }
            .frame(minWidth: 600, minHeight: 500)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Bangumi Header

struct BangumiHeaderView: View {
    let bangumi: Bangumi

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: bangumi.secureCoverURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    Color(.quaternarySystemFill)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 107)
            .background(Color(.quaternarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(bangumi.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text(bangumi.areas)
                    Text("·")
                    Text("\(bangumi.totalEpisodes) 话")
                    if bangumi.score > 0 {
                        Text("·")
                        Label(String(format: "%.1f", bangumi.score), systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)

                Text(bangumi.styles)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Episode List

struct EpisodeListView: View {
    @Environment(AppState.self) private var appState

    private var allSelected: Bool {
        appState.episodes.allSatisfy(\.isSelected)
    }

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            HStack {
                Toggle("全选", isOn: Binding(
                    get: { allSelected },
                    set: { newValue in
                        for i in appState.episodes.indices {
                            appState.episodes[i].isSelected = newValue
                        }
                    }
                ))
                .toggleStyle(.checkbox)

                Spacer()

                let selectedCount = appState.episodes.filter(\.isSelected).count
                Text("已选 \(selectedCount)/\(appState.episodes.count) 话")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            List {
                ForEach($appState.episodes) { $episode in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $episode.isSelected)
                            .toggleStyle(.checkbox)
                            .labelsHidden()

                        VStack(alignment: .leading, spacing: 2) {
                            Text(episode.displayName)
                                .font(.body)

                            Text("CID: \(episode.cid)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}

// MARK: - Export Bar

struct ExportBarView: View {
    @Environment(AppState.self) private var appState
    let viewModel: SearchViewModel
    var dismissSheet: DismissAction

    var body: some View {
        @Bindable var appState = appState

        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)

                Text(appState.exportDirectory.lastPathComponent)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Button("选择") {
                    chooseExportDirectory()
                }
                .controlSize(.small)
            }

            Spacer()

            Button {
                dismissSheet()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    Task {
                        await viewModel.exportSelected(appState: appState)
                    }
                }
            } label: {
                Label("开始导出", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.episodes.filter(\.isSelected).isEmpty || appState.isExporting)
        }
        .padding()
    }

    private func chooseExportDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择导出目录"

        if panel.runModal() == .OK, let url = panel.url {
            appState.exportDirectory = url
        }
    }
}
