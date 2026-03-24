import SwiftUI

struct SearchContentView: View {
    @Environment(AppState.self) private var appState
    let viewModel: SearchViewModel
    @State private var showingEpisodeSheet = false

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !appState.searchQuery.isEmpty {
                    Text("搜索")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                }

                if appState.isSearching {
                    HStack {
                        Spacer()
                        ProgressView("搜索中...")
                            .allowsHitTesting(false)
                            .padding(.top, 100)
                        Spacer()
                    }
                } else if let error = appState.searchError {
                    ContentUnavailableView {
                        Label("搜索失败", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("重试") {
                            Task {
                                await viewModel.search(keyword: appState.searchQuery, appState: appState)
                            }
                        }
                    }
                } else if appState.searchResults.isEmpty && !appState.searchQuery.isEmpty {
                    ContentUnavailableView.search(text: appState.searchQuery)
                } else if appState.searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 80)
                        Image(systemName: "tv")
                            .font(.system(size: 56))
                            .foregroundStyle(.tertiary)
                        Text("搜索番剧名称或输入 CID")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("在左侧搜索栏输入关键词开始")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(appState.searchResults) { bangumi in
                            BangumiCardView(bangumi: bangumi) {
                                Task {
                                    await viewModel.loadEpisodes(for: bangumi, appState: appState)
                                    showingEpisodeSheet = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .task(id: appState.searchQuery) {
            let query = appState.searchQuery.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            await viewModel.search(keyword: query, appState: appState)
        }
        .sheet(isPresented: $showingEpisodeSheet) {
            if appState.selectedBangumi != nil {
                EpisodeSheetView(viewModel: viewModel)
                    .environment(appState)
            }
        }
    }
}


struct BangumiCardView: View {
    let bangumi: Bangumi
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: bangumi.secureCoverURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Color(.quaternarySystemFill)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(.tertiary)
                            }
                    case .empty:
                        Color(.quaternarySystemFill)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(3 / 4, contentMode: .fit)
                .background(Color(.quaternarySystemFill))
                .overlay(alignment: .topTrailing) {
                    if bangumi.score > 0 {
                        Text(String(format: "%.1f", bangumi.score))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(
                    color: .black.opacity(isHovered ? 0.2 : 0.1),
                    radius: isHovered ? 12 : 6,
                    y: isHovered ? 6 : 3
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)

                Text(bangumi.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text("\(bangumi.areas) · \(bangumi.totalEpisodes)话")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
