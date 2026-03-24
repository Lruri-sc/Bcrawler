# Bcrawler — Xcode 构建指南

## 前置条件

- **Xcode 16+**（从 App Store 或 developer.apple.com 安装）
- **macOS 15 Sequoia**
- **Python 3** + requests 库：
  ```bash
  pip3 install requests
  ```

---

## 第一步：创建 Xcode 项目

1. 打开 Xcode → **File → New → Project** (⇧⌘N)
2. 选择平台 **macOS** → 模板选 **App** → Next
3. 填写：
   - **Product Name**: `Bcrawler`
   - **Team**: 你的开发者账号（个人也行）
   - **Organization Identifier**: 如 `com.yourname`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: **None**
   - 取消勾选 Include Tests
4. 选择保存路径 → **Create**

---

## 第二步：设置部署目标

1. 点左侧导航栏最顶部的 **Bcrawler** 项目（蓝色图标）
2. 在 **TARGETS → Bcrawler → General** 标签：
   - **Minimum Deployments** → 改为 **macOS 15.0**

---

## 第三步：创建文件夹结构 (Group)

在 Xcode 左侧 Project Navigator 中，**右键 Bcrawler 文件夹**：

依次创建以下 **Group**（New Group）：

```
Bcrawler/
├── Models/
├── ViewModels/
├── Views/
├── Services/
└── Scripts/         ← 这个后面单独处理
```

操作方式：右键 → **New Group** → 改名

---

## 第四步：添加 Swift 源文件

对于每个 Group，**右键 → New File → Swift File**，按下面的文件名创建，然后把我给你的代码**整个覆盖**进去：

| Group | 文件名 | 对应源码 |
|-------|--------|----------|
| Bcrawler (根) | `BcrawlerApp.swift` | ✅ 已自动生成，覆盖内容 |
| Bcrawler (根) | `AppState.swift` | 新建 |
| Models | `Models.swift` | 新建 |
| ViewModels | `SearchViewModel.swift` | 新建 |
| Views | `ContentView.swift` | ✅ 已自动生成，覆盖内容 |
| Views | `SidebarView.swift` | 新建 |
| Views | `SearchContentView.swift` | 新建 |
| Views | `EpisodeSheetView.swift` | 新建 |
| Views | `LibraryViews.swift` | 新建 |
| Views | `SettingsView.swift` | 新建 |
| Services | `PythonBridge.swift` | 新建 |

> **注意**: Xcode 自动生成的 `BcrawlerApp.swift` 和 `ContentView.swift` 已经存在，直接用我的代码覆盖里面的内容即可。

---

## 第五步：添加 Python 脚本到 Bundle Resources

这步是关键 — Python 脚本需要打包进 App 里，运行时通过 `Bundle.main` 定位。

### 方法：

1. 在 **Finder** 中，找到我给你的 `Scripts/` 文件夹（包含 `search.py`、`fetch_episodes.py`、`fetch_danmaku.py`、`requirements.txt`）

2. **直接把整个 Scripts 文件夹拖进** Xcode 左侧导航栏的 Bcrawler 项目中

3. 弹出的对话框中：
   - ✅ **Copy items if needed**
   - ☑️ **Create folder references**（选这个！蓝色文件夹图标，不是黄色 Group）
   - **Add to targets**: 勾选 `Bcrawler`
   - 点 **Finish**

4. **验证**：左侧导航栏应出现一个**蓝色文件夹图标**的 `Scripts`

5. **再次确认打包**：
   - 点击项目 → **TARGETS → Bcrawler → Build Phases**
   - 展开 **Copy Bundle Resources**
   - 确认 `Scripts` 文件夹在列表里
   - 如果不在，点 `+` 号手动添加

---

## 第六步：配置 App Sandbox 权限

Python 需要网络访问 + 文件写入权限。

1. 点击项目 → **TARGETS → Bcrawler → Signing & Capabilities**
2. 找到 **App Sandbox**（如果没有就点 + Capability 添加）
3. 开启以下权限：
   - **Network → Outgoing Connections (Client)**: ✅
   - **File Access → User Selected File → Read/Write**: ✅
   - **File Access → Downloads Folder → Read/Write**: ✅

> ⚠️ 如果 Sandbox 导致 Python Process 无法执行，开发阶段可以暂时**移除 App Sandbox**：
> Signing & Capabilities → 点 App Sandbox 右上角的 `×` 删除。
> 上架时再加回来。

---

## 第七步：配置 Hardened Runtime（可选但推荐）

调用外部 Python 需要放开部分限制：

1. **TARGETS → Bcrawler → Signing & Capabilities → + Capability → Hardened Runtime**
2. 勾选：
   - ✅ **Allow Execution of JIT-compiled Code**（有些 Python 库需要）
   - ✅ **Disable Library Validation**（加载非签名 Python 动态库）

---

## 第八步：Build & Run

1. 选择顶栏 Scheme 旁的运行设备：**My Mac**
2. 按 **⌘R** 构建运行
3. 窗口应该启动，显示左侧毛玻璃侧边栏 + 右侧空白搜索引导页

---

## 常见问题

### Q: 编译报错 `@Observable` 找不到
→ 确认 Minimum Deployments 设为 macOS 15.0，Xcode 16+

### Q: 搜索没有反应
→ 检查 Scripts 是否正确打包。在终端测试：
```bash
python3 /path/to/Bcrawler.app/Contents/Resources/Scripts/search.py --keyword "进击的巨人"
```

### Q: Python Process 被 Sandbox 拦截
→ 开发阶段移除 App Sandbox。终端看 Console.app 的报错日志。

### Q: 弹幕 XML 返回空
→ 确认网络可用，B 站 API 没有被 VPN/代理影响。可以直接浏览器打开：
`https://comment.bilibili.com/{cid}.xml` 验证。

---

## 项目文件最终结构（Xcode Navigator 里应该长这样）

```
📁 Bcrawler                    (黄色 Group)
├── 📄 BcrawlerApp.swift       (@main 入口)
├── 📄 AppState.swift          (@Observable 全局状态)
├── 📁 Models
│   └── 📄 Models.swift
├── 📁 ViewModels
│   └── 📄 SearchViewModel.swift
├── 📁 Views
│   ├── 📄 ContentView.swift
│   ├── 📄 SidebarView.swift
│   ├── 📄 SearchContentView.swift
│   ├── 📄 EpisodeSheetView.swift
│   ├── 📄 LibraryViews.swift
│   └── 📄 SettingsView.swift
├── 📁 Services
│   └── 📄 PythonBridge.swift
├── 📁 Scripts                  (蓝色 Folder Reference!)
│   ├── 🐍 search.py
│   ├── 🐍 fetch_episodes.py
│   ├── 🐍 fetch_danmaku.py
│   └── 📄 requirements.txt
├── 📄 Bcrawler.entitlements
└── 📁 Assets.xcassets
```
