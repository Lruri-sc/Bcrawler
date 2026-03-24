import SwiftUI
import Observation

@Observable
final class SearchViewModel {
    private let bridge = PythonBridge()

    // MARK: - Search

    func search(keyword: String, appState: AppState) async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        appState.isSearching = true
        appState.searchError = nil
        appState.searchResults = []

        do {
            let results = try await bridge.searchBangumi(keyword: keyword)
            await MainActor.run {
                appState.searchResults = results
                appState.isSearching = false
            }
        } catch {
            await MainActor.run {
                appState.searchError = error.localizedDescription
                appState.isSearching = false
            }
        }
    }

    // MARK: - Load Episodes

    func loadEpisodes(for bangumi: Bangumi, appState: AppState) async {
        appState.selectedBangumi = bangumi
        appState.isLoadingEpisodes = true
        appState.episodes = []

        do {
            let episodes = try await bridge.fetchEpisodes(seasonId: bangumi.seasonId)
            await MainActor.run {
                appState.episodes = episodes
                appState.isLoadingEpisodes = false
            }
        } catch {
            await MainActor.run {
                appState.searchError = error.localizedDescription
                appState.isLoadingEpisodes = false
            }
        }
    }

    // MARK: - Export

    func exportSelected(appState: AppState) async {
        let selectedEpisodes = appState.episodes.filter { $0.isSelected }
        guard !selectedEpisodes.isEmpty else { return }

        appState.isExporting = true
        appState.exportProgress = 0
        appState.exportStatusMessage = "准备导出..."
        appState.exportTasks = selectedEpisodes.map { ExportTask(episode: $0) }

        do {
            try await bridge.exportDanmaku(
                episodes: selectedEpisodes,
                outputDirectory: appState.exportDirectory
            ) { current, total, episode, status in
                Task { @MainActor in
                    appState.exportProgress = Double(current) / Double(total)
                    appState.exportStatusMessage = "正在导出第 \(current)/\(total) 话: \(episode)"

                    // Update individual task status
                    if let idx = appState.exportTasks.firstIndex(where: { $0.episode.cid == selectedEpisodes[current - 1].cid }) {
                        switch status {
                        case "downloading":
                            appState.exportTasks[idx].status = .downloading
                        case "converting":
                            appState.exportTasks[idx].status = .converting
                        case "complete":
                            appState.exportTasks[idx].status = .completed
                        case "error":
                            appState.exportTasks[idx].status = .failed
                        default:
                            break
                        }
                    }
                }
            }

            await MainActor.run {
                appState.isExporting = false
                appState.exportProgress = 1.0
                appState.exportStatusMessage = "导出完成"

                // Add to recent exports
                if let bangumi = appState.selectedBangumi {
                    let recent = RecentExport(
                        bangumiTitle: bangumi.title,
                        episodeCount: selectedEpisodes.count,
                        directoryPath: appState.exportDirectory.path
                    )
                    appState.recentExports.insert(recent, at: 0)
                }
            }
        } catch {
            await MainActor.run {
                appState.isExporting = false
                appState.exportStatusMessage = "导出失败: \(error.localizedDescription)"
            }
        }
    }
}
