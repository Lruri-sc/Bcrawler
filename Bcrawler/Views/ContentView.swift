import SwiftUI
import AppKit
import ObjectiveC

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SidebarView()
        } detail: {
            switch appState.selectedSection {
            case .search:
                SearchContentView()
            case .recentExports:
                RecentExportsView()
            case .favorites:
                FavoritesView()
            case .settings:
                SettingsView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(WindowCloseInterceptor(isExporting: $appState.isExporting))
    }
}

private struct WindowCloseInterceptor: NSViewRepresentable {
    @Binding var isExporting: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.attach(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isExporting = isExporting
        context.coordinator.attach(to: nsView.window)
    }

    final class Coordinator {
        var isExporting: Bool = false
        private weak var window: NSWindow?
        private let delegate = WindowCloseDelegate()
        private static var delegateAssociationKey: UInt8 = 0

        func attach(to candidateWindow: NSWindow?) {
            guard let candidateWindow else { return }
            guard window !== candidateWindow else { return }

            window = candidateWindow
            delegate.isExportingProvider = { [weak self] in
                self?.isExporting ?? false
            }
            candidateWindow.delegate = delegate
            objc_setAssociatedObject(
                candidateWindow,
                &Self.delegateAssociationKey,
                delegate,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    final class WindowCloseDelegate: NSObject, NSWindowDelegate {
        var isExportingProvider: () -> Bool = { false }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            guard isExportingProvider() else { return true }

            let alert = NSAlert()
            alert.messageText = "正在下载，无法立即退出"
            alert.informativeText = "弹幕导出尚未完成。你可以取消退出并等待导出完成，或仍然退出应用。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "取消")
            alert.addButton(withTitle: "退出")

            let result = alert.runModal()
            return result == .alertSecondButtonReturn
        }
    }
}
