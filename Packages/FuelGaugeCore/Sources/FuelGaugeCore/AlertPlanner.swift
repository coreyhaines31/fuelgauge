import Foundation

/// Decides which alerts to send for a refresh's forecasts: once per window when a limit is forecast to run
/// out early, and once per window per usage threshold. A run-out forecast has to hold for two refreshes in a
/// row, so one burst of work can't set it off. Pure, so it can be tested; the app posts what it returns.
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

    /// What carries over between refreshes. `fired` is saved across launches; `shortLastTime` lives in memory.
    public struct State: Sendable, Equatable {
        /// Per limit and kind ("claude/five_hour|short", "claude/five_hour|80"), the reset time of the window
        /// that alert last fired for.
        public var fired: [String: Double]
        public var shortLastTime: Set<LimitKey>

        public init(fired: [String: Double] = [:], shortLastTime: Set<LimitKey> = []) {
            self.fired = fired
            self.shortLastTime = shortLastTime
        }
    }

    public struct Alert: Sendable, Equatable {
        public let id: String
        public let title: String
        public let body: String
    }

    /// Reset times within this much of each other are the same window; they drift a little between readings.
    static let sameWindow: TimeInterval = 600

    public var settings: Settings

    public init(settings: Settings) {
        self.settings = settings
    }

    public func plan(_ forecasts: [Forecast], state: State, now: Date = Date()) -> ([Alert], State) {
        var fired = state.fired
        var shortNow: Set<LimitKey> = []
        var alerts: [Alert] = []

        func hasFired(_ id: String, _ forecast: Forecast) -> Bool {
            fired[id].map { abs($0 - forecast.resetsAt.timeIntervalSince1970) <= Self.sameWindow } ?? false
        }

        for forecast in forecasts where forecast.verdict != .reset {
            if settings.alertWhenShort, case .runsOut(let at, _, _) = forecast.verdict,
               forecast.resetsAt.timeIntervalSince(at) >= settings.minimumMargin {
                shortNow.insert(forecast.key)
                let id = "\(forecast.key.id)|short"
                if state.shortLastTime.contains(forecast.key), !hasFired(id, forecast) {
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
        return (alerts, State(fired: fired, shortLastTime: shortNow))
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
        if let pace = ForecastText.pace(forecast) { body += ". " + pace }
        return body
    }
}
