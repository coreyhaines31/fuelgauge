#if DEBUG
import AppKit
import FuelGaugeCore
import SwiftUI

/// Runs the app on made-up readings, for screenshots and visual checks. Debug builds only.
///
///     --demo                    sample readings in a temporary folder; live readers off
///     --snapshot <file.png>     draw the panel to a PNG and quit (needs no Screen Recording)
///     --dark                    dark appearance
@MainActor
enum DemoMode {
    nonisolated static let isOn = CommandLine.arguments.contains("--demo")
    nonisolated static let folder = FileManager.default.temporaryDirectory.appending(path: "FuelGaugeDemo")

    static var snapshotURL: URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--snapshot"),
              index + 1 < CommandLine.arguments.count else { return nil }
        return URL(filePath: CommandLine.arguments[index + 1])
    }

    static var resetCredits: ResetCredits? {
        let expiry = Date().addingTimeInterval(2 * 86400).timeIntervalSince1970
        let json = """
        {"rateLimitResetCredits":{"availableCount":2,"credits":[{"status":"available","expiresAt":\(expiry)}]}}
        """
        return try? ResetCredits.decode(Data(json.utf8))
    }

    /// Writes sample readings: Claude's 5-hour window running short, its weekly window fine, Codex learning
    /// to be steady, Grok Bot nearly full.
    static func prepare(now: Date = Date()) {
        try? FileManager.default.removeItem(at: folder)
        let store = ReadingStore(folder: folder.appending(path: "Readings"))
        func series(_ provider: Provider, _ limit: String, minutes: Int?, resetsIn hours: Double,
                    _ points: [(minutesAgo: Double, used: Double)]) -> [Reading] {
            points.map {
                Reading(
                    provider: provider, limit: limit, windowMinutes: minutes, usedPercent: $0.used,
                    resetsAt: now.addingTimeInterval(hours * 3600), at: now.addingTimeInterval(-$0.minutesAgo * 60)
                )
            }
        }
        var readings: [Reading] = []
        readings += series(.claude, "five_hour", minutes: 300, resetsIn: 3.1, [
            (110, 8), (95, 14), (80, 21), (65, 27), (50, 34), (35, 41), (20, 47), (8, 52), (1, 55)
        ])
        readings += series(.claude, "seven_day", minutes: 10080, resetsIn: 64, [
            (60 * 30, 18), (60 * 24, 24), (60 * 18, 29), (60 * 12, 33), (60 * 6, 37), (60, 40), (1, 41)
        ])
        readings += series(.codex, "codex-10080", minutes: 10080, resetsIn: 51, [
            (60 * 40, 2), (60 * 30, 4), (60 * 20, 6), (60 * 10, 8), (60 * 2, 9), (5, 9)
        ])
        readings += series(.grokBot, "weekly", minutes: 10080, resetsIn: 35, [
            (60 * 20, 72), (60 * 14, 78), (60 * 8, 84), (60 * 2, 89)
        ])
        try? store.append(readings, now: now)
        NSApp.appearance = NSAppearance(named: CommandLine.arguments.contains("--dark") ? .darkAqua : .aqua)
    }

    /// The menu bar gauge at a few fuel levels and tints, enlarged, beside the panel snapshot.
    private static func saveGlyphs(next url: URL) {
        let glyphs: [(Double?, NSColor?)] = [(nil, nil), (0.9, nil), (0.5, nil), (0.15, .systemOrange), (0, .systemRed)]
        let size = NSSize(width: 18 * glyphs.count * 4 + 8 * 4 * glyphs.count, height: 18 * 4)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()
            for (index, glyph) in glyphs.enumerated() {
                FuelGlyph.image(fuelLeft: glyph.0, tint: glyph.1, size: 72)
                    .draw(in: NSRect(x: CGFloat(index) * 104, y: 0, width: 72, height: 72))
            }
            return true
        }
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return }
        let glyphURL = url.deletingPathExtension().appendingPathExtension("glyph.png")
        try? rep.representation(using: .png, properties: [:])?.write(to: glyphURL)
    }

    /// Draws the panel offscreen and saves it. An app can always draw its own views, so this works without
    /// Screen Recording permission.
    static func snapshot(model: UsageModel, updater: Updater, to url: URL) {
        let panes: [(String, AnyView)] = [
            ("general", AnyView(GeneralSettingsView(updater: updater))),
            ("tools", AnyView(ToolsSettingsView(model: model))),
            ("alerts", AnyView(AlertsSettingsView())),
            ("resets", AnyView(ResetsSettingsView(model: model)))
        ]
        for (name, pane) in panes {
            let paneURL = url.deletingPathExtension().appendingPathExtension("\(name).png")
            render(pane.frame(width: SettingsWindow.paneWidth), to: paneURL)
        }
        let view = PanelView(model: model, openSettings: {}, checkForUpdates: {})
        render(view, to: url) {
            saveGlyphs(next: url)
            NSApp.terminate(nil)
        }
    }

    private static func render(_ view: some View, to url: URL, then done: (() -> Void)? = nil) {
        let hosting = NSHostingView(rootView: view.background(Color(nsColor: .windowBackgroundColor)))
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)
        let window = NSWindow(
            contentRect: NSRect(x: -5000, y: -5000, width: hosting.frame.width, height: hosting.frame.height),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        window.contentView = hosting
        window.orderFrontRegardless()
        hosting.layoutSubtreeIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return }
            hosting.cacheDisplay(in: hosting.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
            window.orderOut(nil)
            done?()
        }
    }
}
#endif
