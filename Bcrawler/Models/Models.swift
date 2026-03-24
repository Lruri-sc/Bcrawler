import Foundation



enum SidebarSection: String, CaseIterable, Identifiable {
    case search = "搜索"
    case recentExports = "最近导出"
    case favorites = "收藏"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .search: "magnifyingglass"
        case .recentExports: "clock"
        case .favorites: "heart"
        case .settings: "gearshape"
        }
    }

    
    var group: SidebarGroup {
        switch self {
        case .search: .navigation
        case .recentExports, .favorites: .library
        case .settings: .library
        }
    }
}

enum SidebarGroup: String, CaseIterable {
    case navigation = "导航"
    case library = "资料库"
}



struct Bangumi: Identifiable, Codable, Hashable {
    let id: Int                   
    let seasonId: Int             
    let title: String
    let coverURL: String          
    let areas: String             
    let styles: String            
    let evaluate: String          
    let totalEpisodes: Int        
    let score: Double             
    var isFavorite: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "media_id"
        case seasonId = "season_id"
        case title, coverURL, areas, styles, evaluate, totalEpisodes, score
    }

    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Bangumi, rhs: Bangumi) -> Bool {
        lhs.id == rhs.id
    }
}



struct Episode: Identifiable, Codable {
    let id: Int                   
    let cid: Int                  
    let aid: Int                  
    let title: String             
    let longTitle: String         
    let badge: String             
    let coverURL: String          
    var isSelected: Bool = true   

    enum CodingKeys: String, CodingKey {
        case id = "ep_id"
        case cid, aid, title, longTitle, badge, coverURL
    }

    
    var displayName: String {
        if longTitle.isEmpty {
            return "第\(title)话"
        }
        return "第\(title)话 - \(longTitle)"
    }
}



struct ExportTask: Identifiable {
    let id = UUID()
    let episode: Episode
    var status: ExportStatus = .pending
    var outputPath: String?
    var errorMessage: String?
}

enum ExportStatus: String {
    case pending = "等待中"
    case downloading = "下载中"
    case converting = "转换中"
    case completed = "完成"
    case failed = "失败"

    var icon: String {
        switch self {
        case .pending: "clock"
        case .downloading: "arrow.down.circle"
        case .converting: "arrow.triangle.2.circlepath"
        case .completed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .pending: "secondary"
        case .downloading, .converting: "blue"
        case .completed: "green"
        case .failed: "red"
        }
    }
}



struct RecentExport: Identifiable, Codable {
    let id: UUID
    let bangumiTitle: String
    let episodeCount: Int
    let exportDate: Date
    let directoryPath: String

    init(bangumiTitle: String, episodeCount: Int, directoryPath: String) {
        self.id = UUID()
        self.bangumiTitle = bangumiTitle
        self.episodeCount = episodeCount
        self.exportDate = Date()
        self.directoryPath = directoryPath
    }
}




struct PythonMessage: Codable {
    let type: MessageType
    let data: MessageData?

    enum MessageType: String, Codable {
        case searchResults = "search_results"
        case episodes = "episodes"
        case progress = "progress"
        case complete = "complete"
        case error = "error"
    }
}

struct MessageData: Codable {
    
    let results: [Bangumi]?

    
    let episodes: [Episode]?

    
    let current: Int?
    let total: Int?
    let episodeTitle: String?
    let status: String?

    
    let filePath: String?

    
    let message: String?
}
