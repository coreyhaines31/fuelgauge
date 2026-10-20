import Foundation
import FuelGaugeCore
import UserNotifications

/// Posts the notifications `AlertPlanner` decides on, and keeps what it has already fired across launches.
@MainActor
final class Alerts {
    private static let firedKey = "firedAlerts"

    private var state = AlertPlanner.State(
        fired: UserDefaults.standard.dictionary(forKey: firedKey) as? [String: Double] ?? [:]
    )
    private var askedPermission = false
    private let center = UNUserNotificationCenter.current()

    func check(_ forecasts: [Forecast], now: Date = Date()) {
        let planner = AlertPlanner(settings: AlertPlanner.Settings(
            alertWhenShort: Preferences.alertWhenShort, thresholds: Preferences.alertThresholds
        ))
        let (alerts, next) = planner.plan(forecasts, state: state, now: now)
        state = next
        UserDefaults.standard.set(next.fired, forKey: Self.firedKey)
        alerts.forEach(post)
    }

    private func post(_ alert: AlertPlanner.Alert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        let request = UNNotificationRequest(identifier: alert.id, content: content, trigger: nil)
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
