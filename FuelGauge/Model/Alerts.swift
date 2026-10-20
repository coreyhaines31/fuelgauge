import Foundation
import FuelGaugeCore
import UserNotifications

/// Notifications when a limit is forecast to run out before reset, and when it crosses 80% and 95%.
/// Each fires once per window, and a run-out forecast has to hold for two refreshes in a row, so one
/// burst of work can't set it off.
@MainActor
final class Alerts {
    private static let firedKey = "firedAlerts"
    /// How much earlier than the reset a run-out has to be before it's worth interrupting for.
    static let minimumMargin: TimeInterval = 30 * 60

    private var shortOnce: Set<String> = []
    private var askedPermission = false
    private let center = UNUserNotificationCenter.current()

    func check(_ forecasts: [Forecast], now: Date = Date()) {
        var fired = UserDefaults.standard.dictionary(forKey: Self.firedKey) as? [String: Double] ?? [:]
        // Forget windows that reset more than a day ago.
        fired = fired.filter { $0.value > now.addingTimeInterval(-86400).timeIntervalSince1970 }
        var shortNow: Set<String> = []

        for forecast in forecasts {
            let window = "\(forecast.key.id)|\(Int(forecast.resetsAt.timeIntervalSince1970 / 600))"
            if Preferences.alertWhenShort, case .runsOut(let at, _, _) = forecast.verdict,
               forecast.resetsAt.timeIntervalSince(at) >= Self.minimumMargin {
                shortNow.insert(window)
                let id = "\(window)|short"
                if shortOnce.contains(window), fired[id] == nil {
                    fired[id] = forecast.resetsAt.timeIntervalSince1970
                    post(id: id, title: shortTitle(forecast, at: at, now: now), body: shortBody(forecast, now: now))
                }
            }
            for threshold in Preferences.alertThresholds where forecast.usedPercent >= Double(threshold) {
                let id = "\(window)|\(threshold)"
                guard fired[id] == nil, forecast.verdict != .reset else { continue }
                // Crossing several at once (say, a first reading at 97%) alerts for the highest only.
                for lower in Preferences.alertThresholds where lower < threshold {
                    fired["\(window)|\(lower)"] = forecast.resetsAt.timeIntervalSince1970
                }
                fired[id] = forecast.resetsAt.timeIntervalSince1970
                if threshold == Preferences.alertThresholds.filter({ forecast.usedPercent >= Double($0) }).max() {
                    post(
                        id: id,
                        title: "\(name(forecast)) is \(ForecastText.percent(forecast.usedPercent)) used",
                        body: ForecastText.headline(forecast, now: now) + ". " + ForecastText.usage(forecast, now: now)
                    )
                }
            }
        }
        shortOnce = shortNow
        UserDefaults.standard.set(fired, forKey: Self.firedKey)
    }

    private func name(_ forecast: Forecast) -> String {
        "\(forecast.key.provider.name)'s \(forecast.windowName.lowercased()) limit"
    }

    private func shortTitle(_ forecast: Forecast, at: Date, now: Date) -> String {
        "\(name(forecast)) runs out around \(ForecastText.time(at, now: now))"
    }

    private func shortBody(_ forecast: Forecast, now: Date) -> String {
        let resets = ForecastText.time(forecast.resetsAt, now: now)
        var body = "That's before it resets at \(resets)"
        if case .runsOut(let at, _, _) = forecast.verdict {
            let early = ForecastText.duration(forecast.resetsAt.timeIntervalSince(at))
            body = "That's \(early) before it resets at \(resets)"
        }
        if let pace = ForecastText.pace(forecast) { body += ". " + pace }
        return body
    }

    private func post(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        let center = center
        if askedPermission {
            center.add(request)
            return
        }
        askedPermission = true
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted { center.add(request) }
        }
    }
}
