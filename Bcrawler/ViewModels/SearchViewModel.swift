import SwiftUI
import Observation

@Observable
final class SearchViewModel {
    private let bridge = PythonBridge()


    func search(keyword: String, appState: AppState) async {
        guard !keyword.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        appState.isSearching = true
        appState.searchError = nil
        appState.searchResults = []

        do {
            let results = try await bridge.searchBangumi(keyword: keyword)
            guard !Task.isCancelled else {
                appState.isSearching = false
                return
            }
            await MainActor.run {
                appState.searchResults = results
                appState.isSearching = false
            }
        } catch is CancellationError {
            appState.isSearching = false
            return
        } catch {
            guard !Task.isCancelled else {
                appState.isSearching = false
                return
            }
            await MainActor.run {
                appState.searchError = error.localizedDescription
                appState.isSearching = false
            }
        }
    }


    func loadEpisodes(for bangumi: Bangumi, appState: AppState) async {
        appState.selectedBangumi = bangumi
        appState.isLoadingEpisodes = true
        appState.episodes = []

        do {
            let episodes = try await bridge.fetchEpisodes(seasonId: bangumi.seasonId)
            guard !Task.isCancelled else {
                appState.isLoadingEpisodes = false
                return
            }
            await MainActor.run {
                appState.episodes = episodes
                appState.isLoadingEpisodes = false
            }
        } catch is CancellationError {
            appState.isLoadingEpisodes = false
            return
        } catch {
            guard !Task.isCancelled else {
                appState.isLoadingEpisodes = false
                return
            }
            await MainActor.run {
                appState.searchError = error.localizedDescription
                appState.isLoadingEpisodes = false
            }
        }
    }


    func exportSelected(appState: AppState) async {
        let selectedEpisodes = appState.episodes.filter { $0.isSelected }
        guard !selectedEpisodes.isEmpty else { return }
        var lastProgressUIUpdate = Date.distantPast

        appState.isExporting = true
        appState.exportProgress = 0
        appState.exportStatusMessage = "准备导出..."
        appState.exportTasks = selectedEpisodes.map { ExportTask(episode: $0) }

        do {
            try await bridge.exportDanmaku(
                episodes: selectedEpisodes,
                outputDirectory: appState.exportDirectory
            ) { current, total, episode, status in
                let now = Date()
                let shouldForceUpdate = (status == "complete" || status == "error" || current == total)
                guard shouldForceUpdate || now.timeIntervalSince(lastProgressUIUpdate) >= 0.12 else {
                    return
                }
                lastProgressUIUpdate = now

                Task { @MainActor in
                    guard total > 0 else { return }
                    appState.exportProgress = Double(current) / Double(total)
                    appState.exportStatusMessage = "正在导出第 \(current)/\(total) 话: \(episode)"

                    if current >= 1,
                       current <= selectedEpisodes.count,
                       let idx = appState.exportTasks.firstIndex(where: { $0.episode.cid == selectedEpisodes[current - 1].cid }) {
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
