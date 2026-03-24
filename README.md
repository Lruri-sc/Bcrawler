# Bcrawler

一个 macOS 上的 B 站番剧弹幕导出工具：搜索番剧、读取分集、批量导出 `.ass` 字幕。

## 环境要求

- macOS 15+
- Xcode 16+
- Python 3（建议 3.9+）


安装 Python 依赖（在项目目录执行）  
   `pip3 install -r Bcrawler/Scripts/requirements.txt`


## 功能流程

1. `search.py`：关键词搜索番剧  
2. `fetch_episodes.py`：根据 `season_id` 拉取分集  
3. `fetch_danmaku.py`：根据 `cid` 下载 XML 并转换为 `.ass`  
4. Swift 通过 `PythonBridge` 调 Python，stdout JSON 回传进度和结果

## Python 环境排查

### 1) 提示找不到 Python

- 在终端验证：`which python3`
- 在 App 设置页把 Python 路径改成终端输出的绝对路径（例如 `/opt/homebrew/bin/python3`）
- 再验证：`python3 --version`

### 2) 能启动但搜索/导出失败

- 重新安装依赖：  
  `pip3 install -r Bcrawler/Scripts/requirements.txt --upgrade`
- 直接测试脚本：  
  `python3 Bcrawler/Scripts/search.py --keyword "进击的巨人"`

### 3) Xcode 运行正常但 App 内脚本报错

- 检查 `Scripts` 是否真的在 `Copy Bundle Resources`
- 确认是“文件夹引用”（蓝色文件夹）而不是普通分组
- 清理后重编译：`Shift + Command + K` 再 `⌘R`

### 4) 网络相关报错

- 检查代理/VPN 是否拦截 B 站接口
- 在浏览器直接访问：`https://comment.bilibili.com/{cid}.xml`

### 5) 沙盒权限导致失败

- 在 Xcode 的 `Signing & Capabilities` 中检查：
  - Network Outgoing Connections
  - 用户选择目录读写权限

## 目录说明

```text
Bcrawler/
├── BcrawlerApp/      # App 入口与全局状态
├── Models/           # 数据模型
├── ViewModels/       # 业务逻辑
├── Views/            # 界面
├── Services/         # PythonBridge
└── Scripts/          # Python 脚本
```
