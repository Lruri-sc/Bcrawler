# Bcrawler

macOS 原生弹幕爬取工具 — 搜索 B 站番剧，批量导出弹幕为 `.ass` 字幕文件。

## 截图

UI 参考 Apple TV app 风格：毛玻璃侧边栏 + 网格内容区 + 集数勾选面板。

## 技术架构

```
┌──────────────────────────────────────────────────────┐
│  SwiftUI (macOS 15+)                                 │
│  ┌──────────┐  ┌─────────────┐  ┌──────────────┐    │
│  │ Views    │→ │ ViewModels  │→ │ PythonBridge │    │
│  │ (HIG UI) │  │ (@Observable)│  │ (Process)    │    │
│  └──────────┘  └─────────────┘  └──────┬───────┘    │
└─────────────────────────────────────────┼────────────┘
                                          │ stdout JSON
┌─────────────────────────────────────────┼────────────┐
│  Python 3 Scripts                       ▼            │
│  ┌───────────┐  ┌─────────────────┐  ┌───────────┐  │
│  │ search.py │  │fetch_episodes.py│  │fetch_danmaku│ │
│  │           │  │                 │  │   .py      │  │
│  └───────────┘  └─────────────────┘  └───────────┘  │
└──────────────────────────────────────────────────────┘
```

## B 站 API 映射链

```
搜索关键词
  → /x/web-interface/search/type?search_type=media_bangumi
    → season_id

season_id
  → /pgc/view/web/season?season_id=xxx
    → episodes[]{ep_id, cid, aid, title, long_title}

cid
  → https://comment.bilibili.com/{cid}.xml
    → 弹幕 XML → 解析 → ASS 字幕
```

## 项目结构

```
Bcrawler/
├── BcrawlerApp/
│   ├── BcrawlerApp.swift      # @main App 入口
│   └── AppState.swift            # 全局 @Observable 状态
├── Models/
│   └── Models.swift              # Bangumi, Episode, ExportTask 等数据模型
├── ViewModels/
│   └── SearchViewModel.swift     # 搜索/加载/导出业务逻辑
├── Views/
│   ├── ContentView.swift         # NavigationSplitView 主布局
│   ├── SidebarView.swift         # 毛玻璃侧边栏 + 搜索
│   ├── SearchContentView.swift   # 搜索结果网格
│   ├── EpisodeSheetView.swift    # 集数勾选 + 导出面板
│   ├── LibraryViews.swift        # 最近导出 / 收藏
│   └── SettingsView.swift        # Python 路径 + 导出目录
├── Services/
│   └── PythonBridge.swift        # Swift ↔ Python Process 桥接
└── Scripts/
    ├── search.py                 # B站番剧搜索
    ├── fetch_episodes.py         # season_id → episode(cid) 列表
    ├── fetch_danmaku.py          # cid → 弹幕XML → ASS 转换
    └── requirements.txt          # pip install -r requirements.txt
```

## 开发环境

- **Xcode 16+**
- **macOS 15 Sequoia**
- **Python 3.9+**（系统自带或 Homebrew）
- `pip install -r Scripts/requirements.txt`

## 构建步骤

1. 克隆仓库
2. `pip3 install -r Scripts/requirements.txt`
3. 在 Xcode 中打开项目
4. 将 `Scripts/` 目录添加到 target 的 "Copy Bundle Resources"
5. Build & Run (⌘R)

## Swift ↔ Python 通信协议

Python 脚本通过 stdout 输出 JSON，每行一个对象：

```jsonc
// 搜索结果 (search.py → stdout)
[{"media_id": 123, "season_id": 456, "title": "...", ...}]

// 集数列表 (fetch_episodes.py → stdout)
[{"ep_id": 1, "cid": 789, "title": "1", "longTitle": "...", ...}]

// 导出进度 (fetch_danmaku.py → stdout, 逐行)
{"current": 1, "total": 12, "episode": "第1话", "status": "downloading"}
{"current": 1, "total": 12, "episode": "第1话", "status": "converting"}
{"current": 1, "total": 12, "episode": "第1话", "status": "complete", "filePath": "/path/to/ep1.ass"}
```

## 许可证

MIT
