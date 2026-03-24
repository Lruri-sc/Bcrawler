import SwiftUI


struct RecentExportsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.recentExports.isEmpty {
                ContentUnavailableView {
                    Label("暂无导出记录", systemImage: "clock")
                } description: {
                    Text("导出的弹幕文件会显示在这里")
                }
            } else {
                List(appState.recentExports) { export in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(export.bangumiTitle)
                                .font(.body)
                                .fontWeight(.medium)

                            Text("\(export.episodeCount) 话 · \(export.exportDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            NSWorkspace.shared.open(URL(fileURLWithPath: export.directoryPath))
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                        .help("在 Finder 中打开")
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("最近导出")
    }
}


struct FavoritesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            let favorites = appState.searchResults.filter(\.isFavorite)
            if favorites.isEmpty {
                ContentUnavailableView {
                    Label("暂无收藏", systemImage: "heart")
                } description: {
                    Text("收藏的番剧会显示在这里")
                }
            } else {
                List(favorites) { bangumi in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                            .frame(width: 64, height: 36)
                            .overlay {
                                Image(systemName: "play.tv")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                        VStack(alignment: .leading) {
                            Text(bangumi.title)
                                .font(.body)
                            Text("\(bangumi.areas) · \(bangumi.totalEpisodes)话")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("收藏")
    }
}
