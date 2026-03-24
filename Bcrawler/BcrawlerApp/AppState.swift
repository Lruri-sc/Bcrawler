import SwiftUI
import Observation

@Observable
final class AppState {
    var selectedSection: SidebarSection = .search
    var searchQuery: String = ""

    var exportDirectory: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    var pythonPath: String = "/usr/bin/python3"

    var searchResults: [Bangumi] = []
    var isSearching: Bool = false
    var searchError: String?

    var selectedBangumi: Bangumi?
    var episodes: [Episode] = []
    var isLoadingEpisodes: Bool = false

    var exportTasks: [ExportTask] = []
    var isExporting: Bool = false
    var exportProgress: Double = 0
    var exportStatusMessage: String = "就绪"

    var recentExports: [RecentExport] = []
}
