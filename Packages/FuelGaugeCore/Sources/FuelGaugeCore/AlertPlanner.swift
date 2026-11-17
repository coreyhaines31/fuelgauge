import Foundation

/// Decides which alerts to send for a refresh's forecasts: once per window when a limit is forecast to run
/// out early, and once per window per usage threshold. A run-out warning needs two distinct, recent source
/// readings from the same window. Refreshing a cached reading cannot confirm it.
public struct AlertPlanner: Sendable {
    public struct Settings: Sendable {
        public var alertWhenShort: Bool
        public var thresholds: [Int]
        /// How much earlier than the reset a run-out has to be before it's worth interrupting for.
        public var minimumMargin: TimeInterval

        public init(alertWhenShort: Bool, thresholds: [Int], minimumMargin: TimeInterval = 30 * 60) {
            self.alertWhenShort = alertWhenShort
            self.thresholds = thresholds
            self.minimumMargin = minimumMargin
        }
    }

    /// Only `fired` is saved across launches; pending confirmations live in memory.
    public struct State: Sendable, Equatable {
        /// Per limit and kind ("claude/five_hour|short", "claude/five_hour|80"), the reset time of the window
        /// that alert last fired for.
        public var fired: [String: Double]
        public var pendingShorts: [LimitKey: Confirmation]

        public init(fired: [String: Double] = [:], pendingShorts: [LimitKey: Confirmation] = [:]) {
            self.fired = fired
            self.pendingShorts = pendingShorts
        }
    }

    public struct Confirmation: Sendable, Equatable {
        let readingAt: Date
        let resetsAt: Date
        let windowMinutes: Int?
        let usedPercent: Double

        init(_ forecast: Forecast) {
            readingAt = forecast.lastReadingAt
            resetsAt = forecast.resetsAt
            windowMinutes = forecast.windowMinutes
            usedPercent = forecast.usedPercent
        }

        func confirms(_ forecast: Forecast, now: Date) -> Bool {
            forecast.lastReadingAt > readingAt && now.timeIntervalSince(readingAt) <= confirmationLifetime
                && abs(resetsAt.timeIntervalSince(forecast.resetsAt)) <= sameWindow
                && windowMinutes == forecast.windowMinutes && forecast.usedPercent >= usedPercent
        }
    }

    public struct Alert: Sendable, Equatable {
        public let id: String
        public let title: String
        public let body: String
    }

    /// Reset times within this much of each other are the same window; they drift a little between readings.
    static let sameWindow: TimeInterval = 600
    static let confirmationLifetime: TimeInterval = 15 * 60

    public var settings: Settings

    public init(settings: Settings) {
        self.settings = settings
    }

    public func plan(_ forecasts: [Forecast], state: State, now: Date = Date()) -> ([Alert], State) {
        var fired = state.fired
        var pendingShorts: [LimitKey: Confirmation] = [:]
        var alerts: [Alert] = []

        func hasFired(_ id: String, _ forecast: Forecast) -> Bool {
            fired[id].map { abs($0 - forecast.resetsAt.timeIntervalSince1970) <= Self.sameWindow } ?? false
        }

        for forecast in forecasts where forecast.verdict != .reset && forecast.verdict != .stale {
            if let at = candidate(forecast, now: now) {
                let previous = state.pendingShorts[forecast.key]
                // A backwards timestamp breaks confirmation instead of becoming a replayable new baseline.
                if previous.map({ forecast.lastReadingAt >= $0.readingAt }) ?? true {
                    pendingShorts[forecast.key] = Confirmation(forecast)
                }
                let id = "\(forecast.key.id)|short"
                if previous?.confirms(forecast, now: now) == true, !hasFired(id, forecast) {
                    fired[id] = forecast.resetsAt.timeIntervalSince1970
                    alerts.append(Alert(id: id, title: Self.shortTitle(forecast, at: at, now: now),
                                        body: Self.shortBody(forecast, at: at, now: now)))
                }
            }
            let crossed = settings.thresholds.filter { forecast.usedPercent >= Double($0) }
            let unfired = crossed.filter { !hasFired("\(forecast.key.id)|\($0)", forecast) }
            // Crossing several at once (say, a first reading at 97%) alerts for the highest only.
            guard let highest = unfired.max() else { continue }
            for threshold in crossed {
                fired["\(forecast.key.id)|\(threshold)"] = forecast.resetsAt.timeIntervalSince1970
            }
            alerts.append(Alert(
                id: "\(forecast.key.id)|\(highest)",
                title: "\(Self.name(forecast)) is \(ForecastText.percent(forecast.usedPercent)) used",
                body: ForecastText.headline(forecast, now: now) + ". " + ForecastText.usage(forecast, now: now)
            ))
        }
        return (alerts, State(fired: fired, pendingShorts: pendingShorts))
    }

    private func candidate(_ forecast: Forecast, now: Date) -> Date? {
        guard settings.alertWhenShort, case .runsOut(let at, _, _) = forecast.verdict, at > now,
              forecast.resetsAt.timeIntervalSince(at) >= settings.minimumMargin,
              forecast.lastReadingAt <= now,
              now.timeIntervalSince(forecast.lastReadingAt) <= Self.confirmationLifetime else { return nil }
        return at
    }

    static func name(_ forecast: Forecast) -> String {
        "\(forecast.key.provider.name)'s \(forecast.windowName.lowercased()) limit"
    }

    static func shortTitle(_ forecast: Forecast, at: Date, now: Date) -> String {
        "\(name(forecast)) runs out around \(ForecastText.time(at, now: now))"
    }

    static func shortBody(_ forecast: Forecast, at: Date, now: Date) -> String {
        let early = ForecastText.duration(forecast.resetsAt.timeIntervalSince(at))
        var body = "That's \(early) before it resets at \(ForecastText.time(forecast.resetsAt, now: now))"
        if let pace = ForecastText.pace(forecast, now: now) { body += ". " + pace }
        return body
    }
}
