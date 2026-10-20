import AppKit
import SwiftUI

/// Hosts a SwiftUI view in a standard window that's created once and reused.
@MainActor
final class HostedWindow {
    private let title: String
    private let size: NSSize
    private let resizable: Bool
    private let makeView: () -> AnyView
    private var window: NSWindow?

    init(title: String, size: NSSize, resizable: Bool = true, view: @escaping () -> some View) {
        self.title = title
        self.size = size
        self.resizable = resizable
        self.makeView = { AnyView(view()) }
    }

    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: makeView())
            // Keep the size set here; a List's ideal height would otherwise stretch the window.
            controller.sizingOptions = []
            let window = NSWindow(contentViewController: controller)
            window.title = title
            window.styleMask = resizable ? [.titled, .closable, .resizable, .miniaturizable] : [.titled, .closable]
            window.setContentSize(size)
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }
}
