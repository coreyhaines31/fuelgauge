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

    /// Limits that were short at the last refresh; a run-out alert needs two in a row.
    private var shortOnce: Set<LimitKey> = []
    private var askedPermission = false
    private let center = UNUserNotificationCenter.current()

    func check(_ forecasts: [Forecast], now: Date = Date()) {
        // Each alert kind per limit remembers the reset time of the window it fired for. A reset time
        // within 10 minutes of that is the same window (reset times drift a little between readings).
        var fired = UserDefaults.standard.dictionary(forKey: Self.firedKey) as? [String: Double] ?? [:]
        func hasFired(_ id: String, _ forecast: Forecast) -> Bool {
            fired[id].map { abs($0 - forecast.resetsAt.timeIntervalSince1970) <= 600 } ?? false
        }
        func markFired(_ id: String, _ forecast: Forecast) {
            fired[id] = forecast.resetsAt.timeIntervalSince1970
        }
        var shortNow: Set<LimitKey> = []

        for forecast in forecasts where forecast.verdict != .reset {
            if Preferences.alertWhenShort, case .runsOut(let at, _, _) = forecast.verdict,
               forecast.resetsAt.timeIntervalSince(at) >= Self.minimumMargin {
                shortNow.insert(forecast.key)
                let id = "\(forecast.key.id)|short"
                if shortOnce.contains(forecast.key), !hasFired(id, forecast) {
                    markFired(id, forecast)
                    post(id: id, title: shortTitle(forecast, at: at, now: now), body: shortBody(forecast, now: now))
                }
            }
            let crossed = Preferences.alertThresholds.filter { forecast.usedPercent >= Double($0) }
            let unfired = crossed.filter { !hasFired("\(forecast.key.id)|\($0)", forecast) }
            // Crossing several at once (say, a first reading at 97%) alerts for the highest only.
            guard let highest = unfired.max() else { continue }
            crossed.forEach { markFired("\(forecast.key.id)|\($0)", forecast) }
            post(
                id: "\(forecast.key.id)|\(highest)",
                title: "\(name(forecast)) is \(ForecastText.percent(forecast.usedPercent)) used",
                body: ForecastText.headline(forecast, now: now) + ". " + ForecastText.usage(forecast, now: now)
            )
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
