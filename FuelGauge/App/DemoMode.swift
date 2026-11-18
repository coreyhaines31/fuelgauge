#if DEBUG
import AppKit
import FuelGaugeCore
import SwiftUI

/// Runs the app on made-up readings, for screenshots and visual checks. Debug builds only.
///
///     --demo                    sample readings in a temporary folder; live readers off
///     --snapshot <file.png>     draw the panel to a PNG and quit (needs no Screen Recording)
///     --dark                    dark appearance
///     --accounts                a second Claude Code account ("Work"), and a Codex folder to add
///     --limit-reached           Grok Bot's weekly limit used up, for the longest verdict
///     --panel-height <points>   the room below the menu bar the panel gets, to check it fits
@MainActor
enum DemoMode {
    nonisolated static let isOn = CommandLine.arguments.contains("--demo")
    nonisolated static let folder = FileManager.default.temporaryDirectory.appending(path: "FuelGaugeDemo")
    nonisolated static let showsAccounts = CommandLine.arguments.contains("--accounts")
    /// A made-up home folder for the account folders, so pictures never show a real sign-in.
    nonisolated static let home = folder.appending(path: "home")

    /// The demo's accounts, never saved: Claude Code's default account and "Work", and Codex's default.
    static var accounts: AccountList {
        var list = AccountList([.defaultAccount(.claude, environment: [:], home: home),
                                .defaultAccount(.codex, environment: [:], home: home)])
        if showsAccounts { list.add(workAccount) }
        return list
    }

    static var workAccount: Account {
        Account.make(.claude, folder: home.appending(path: ".claude-work").path, home: home)
    }

    /// Account folders with who's signed in, plus a Codex folder that isn't tracked yet.
    private static func prepareHome() {
        let folders: [(String, [String: Any])] = [
            (".claude", [:]),
            (".claude-work", ["oauthAccount": ["emailAddress": "sam@acme.example", "organizationName": "Acme",
                                               "planDisplayName": "Team"]]),
            (".codex", [:]),
            (".codex-client", [:])
        ]
        for (name, config) in folders {
            let url = home.appending(path: name)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let file = name.hasPrefix(".codex") ? "auth.json" : ".claude.json"
            try? JSONSerialization.data(withJSONObject: config).write(to: url.appending(path: file))
        }
        let main = ["oauthAccount": ["emailAddress": "sam@example.com", "planDisplayName": "Max"]]
        try? JSONSerialization.data(withJSONObject: main).write(to: home.appending(path: ".claude.json"))
    }

    static var panelHeight: CGFloat? {
        guard let index = CommandLine.arguments.firstIndex(of: "--panel-height"),
              index + 1 < CommandLine.arguments.count else { return nil }
        return Double(CommandLine.arguments[index + 1]).map { CGFloat($0) }
    }

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

    static func usageEvents(now: Date = Date()) -> [UsageEvent] {
        (0..<60).flatMap { day in
            [Provider.claude, .codex].map { provider in
                let at = Calendar.current.date(byAdding: .day, value: -day, to: now)!.addingTimeInterval(-120)
                let scale = Int64(8 + (day * 7) % 17)
                return UsageEvent(id: "demo-\(provider.rawValue)-\(day)", provider: provider,
                                  session: "session-\(day)",
                                  project: day % 2 == 0 ? "/projects/fuelgauge" : "/projects/site",
                                  model: provider == .claude ? "claude-sonnet-4-6" : "gpt-6.1-sol", at: at,
                                  tokens: TokenUsage(input: scale * 12_000, output: scale * 2_000,
                                                     cacheRead: scale * 35_000, cacheWrite: scale * 3_000))
            }
        }
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
        let grokNow: Double = CommandLine.arguments.contains("--limit-reached") ? 100 : 89
        readings += series(.grokBot, "weekly", minutes: 10080, resetsIn: 35, [
            (60 * 20, 72), (60 * 14, 78), (60 * 8, 84), (60 * 2, grokNow)
        ])
        if showsAccounts {
            prepareHome()
            let work = workAccount.slug
            readings += series(.claude, "five_hour", minutes: 300, resetsIn: 1.4, [
                (180, 10), (120, 18), (60, 24), (20, 27), (2, 28)
            ]).map { var reading = $0; reading.account = work; return reading }
            readings += series(.claude, "seven_day", minutes: 10080, resetsIn: 30, [
                (60 * 48, 40), (60 * 36, 51), (60 * 24, 60), (60 * 12, 68), (60 * 4, 73), (2, 75)
            ]).map { var reading = $0; reading.account = work; return reading }
            readings += series(.claude, ModelLimit.limit(forModel: "Fable"), minutes: 10080, resetsIn: 64, [
                (60 * 30, 8), (60 * 12, 14), (60, 19)
            ])
        }
        if CommandLine.arguments.contains("--forecast-demo") { readings = ForecastDemo.readings(now: now) }
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
        let detailsURL = url.deletingPathExtension().appendingPathExtension("details.png")
        render(ForecastDetailsView(model: model).frame(width: 760, height: 900), to: detailsURL)
        if CommandLine.arguments.contains("--forecast-demo") {
            ForecastTimelineDemo.save(next: url)
            SessionPlanDemo.save(next: url)
            saveSchedules(model: model, next: url)
            model.setDemoForecastHistory(ForecastDemo.journal(now: Date()), now: Date())
            let learnedURL = url.deletingPathExtension().appendingPathExtension("learned.png")
            let key = model.forecasts.first(where: { $0.key.provider == .codex })?.key.id ?? ""
            render(ForecastDetailsView(model: model, selectedKey: key).frame(width: 760, height: 1200), to: learnedURL)
            let staleURL = url.deletingPathExtension().appendingPathExtension("stale.png")
            let staleKey = model.forecasts.first(where: { $0.verdict == .stale })?.key.id ?? ""
            render(ForecastDetailsView(model: model, selectedKey: staleKey)
                .frame(width: 760, height: 900), to: staleURL)
            let details = VStack(alignment: .leading, spacing: 14) {
                ForEach(model.forecasts, id: \.key) { forecast in
                    ToolCard(provider: forecast.key.provider, forecasts: [forecast], now: Date(),
                             chartKey: forecast.key)
                }
            }.padding(14).frame(width: 360)
            render(details, to: url.deletingPathExtension().appendingPathExtension("forecasts.png"))
        }
        let usageURL = url.deletingPathExtension().appendingPathExtension("usage.png")
        render(UsageView(model: model).frame(width: 900, height: 850), to: usageURL)
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
        let view = PanelView(model: model, space: PanelSpace(availableHeight: panelHeight), openSettings: {},
                             checkForUpdates: {})
        render(view, to: url) {
            saveGlyphs(next: url)
            NSApp.terminate(nil)
        }
    }

    private static func saveSchedules(model: UsageModel, next url: URL) {
        if let forecast = model.forecasts.first(where: { $0.key.provider == .codex }),
           let profile = forecast.scheduleProfile {
            render(ScheduleProfileView(profile: profile, isApplied: forecast.basis == .schedule,
                                       selectedID: "weekday-10").padding(20).frame(width: 700),
                   to: url.deletingPathExtension().appendingPathExtension("schedule.png"))
        }
        let now = Date()
        if let forecast = ForecastEngine.forecast(for: ForecastDemo.sparseReadings(now: now), now: now),
           let profile = forecast.scheduleProfile {
            for (name, selected) in [("sparse", "weekend-10"), ("unknown", "weekday-2")] {
                render(ScheduleProfileView(profile: profile, isApplied: false, selectedID: selected)
                    .padding(20).frame(width: 700),
                       to: url.deletingPathExtension().appendingPathExtension("\(name).png"))
            }
        }
        if let forecast = ForecastEngine.forecast(for: ForecastDemo.burstReadings(now: now), now: now),
           let profile = forecast.scheduleProfile {
            render(ScheduleProfileView(profile: profile, isApplied: forecast.basis == .schedule)
                .padding(20).frame(width: 700),
                   to: url.deletingPathExtension().appendingPathExtension("burst.png"))
        }
    }

    static func render(_ view: some View, to url: URL, then done: (() -> Void)? = nil) {
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
            // The panel's scroll area sizes itself to its content after the first layout.
            hosting.setFrameSize(hosting.fittingSize)
            hosting.layoutSubtreeIfNeeded()
            guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return }
            hosting.cacheDisplay(in: hosting.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
            window.orderOut(nil)
            done?()
        }
    }
}
#endif
