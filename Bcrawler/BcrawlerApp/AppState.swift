import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - Navigation
    var selectedSection: SidebarSection = .search
    var searchQuery: String = ""

    // MARK: - Settings
    var exportDirectory: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    var pythonPath: String = "/usr/bin/python3"

    // MARK: - Search Results
    var searchResults: [Bangumi] = []
    var isSearching: Bool = false
    var searchError: String?

    // MARK: - Selected Bangumi
    var selectedBangumi: Bangumi?
    var episodes: [Episode] = []
    var isLoadingEpisodes: Bool = false

    // MARK: - Export
    var exportTasks: [ExportTask] = []
    var isExporting: Bool = false
    var exportProgress: Double = 0
    var exportStatusMessage: String = "就绪"

    // MARK: - History
    var recentExports: [RecentExport] = []
}
