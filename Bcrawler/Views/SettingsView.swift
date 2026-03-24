import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section("Python 配置") {
                HStack {
                    TextField("Python3 路径", text: $appState.pythonPath)
                        .textFieldStyle(.roundedBorder)

                    Button("检测") {
                        detectPython()
                    }
                }
                Text("通常为 /usr/bin/python3 或 /usr/local/bin/python3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("导出设置") {
                HStack {
                    Text("默认导出目录")
                    Spacer()
                    Text(appState.exportDirectory.path)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button("选择...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = true
                        if panel.runModal() == .OK, let url = panel.url {
                            appState.exportDirectory = url
                        }
                    }
                }
            }

            Section("关于") {
                LabeledContent("版本", value: "1.0.0")
                LabeledContent("构建", value: "macOS 15+, SwiftUI")
                Link("GitHub", destination: URL(string: "https://github.com")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("设置")
        .frame(minWidth: 450)
    }

    private func detectPython() {
        let paths = [
            "/usr/bin/python3",
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3"
        ]

        for path in paths {
            if FileManager.default.isExecutableFile(atPath: path) {
                appState.pythonPath = path
                return
            }
        }
    }
}
