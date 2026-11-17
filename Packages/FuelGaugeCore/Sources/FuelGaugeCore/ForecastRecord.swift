import Foundation

/// A frozen prediction made by the running app, never reconstructed from later history.
public struct ForecastRecord: Codable, Sendable, Equatable {
    public let issuedAt: Date
    public let appVersion: String
    public let source: Reading
    public let basis: String
    public let verdict: String
    public var targets: [Target]

    public struct Estimate: Codable, Sendable, Equatable {
        let startUsed: Double
        let endUsed: Double
        let endsAt: Date

        init?(_ forecast: Forecast, target: Date, origin: Date) {
            var end = min(target.addingTimeInterval(900), forecast.resetsAt)
            if case .runsOut(let at, _, _) = forecast.verdict, at > target { end = min(end, at) }
            guard var startUsed = ForecastBacktest.projectedUsage(forecast, at: target, origin: origin),
                  var endUsed = ForecastBacktest.projectedUsage(forecast, at: end, origin: origin) else { return nil }
            if case .runsOut(let at, _, _) = forecast.verdict {
                if target >= at { startUsed = 100 }
                if end >= at { endUsed = 100 }
            }
            self.startUsed = startUsed
            self.endUsed = endUsed
            self.endsAt = end
        }

        func usage(at date: Date, target: Date) -> Double {
            let duration = endsAt.timeIntervalSince(target)
            guard duration > 0 else { return startUsed }
            let fraction = min(1, max(0, date.timeIntervalSince(target) / duration))
            return startUsed + (endUsed - startUsed) * fraction
        }
    }

    public enum Outcome: String, Codable, Sendable {
        case pending, observed, missing, changed, unreliable, beyondReset
    }

    public struct Target: Codable, Sendable, Equatable {
        public let hours: Int
        public let at: Date
        public let adaptive: Estimate?
        public let recent: Estimate?
        public var outcome: Outcome = .pending
        public var actual: Reading?
        public var receivedAt: Date?
    }

    init(forecast: Forecast, recent: Forecast?, source: Reading, now: Date, appVersion: String) {
        issuedAt = now
        self.appVersion = appVersion
        self.source = source
        basis = forecast.basis.rawValue
        verdict = ForecastJSON(forecast).verdict
        targets = [1, 6, 24].map { hours in
            let at = now.addingTimeInterval(Double(hours) * 3600)
            guard at < forecast.resetsAt else {
                return Target(hours: hours, at: at, adaptive: nil, recent: nil, outcome: .beyondReset)
            }
            return Target(hours: hours, at: at,
                          adaptive: Estimate(forecast, target: at, origin: now),
                          recent: recent.flatMap { Estimate($0, target: at, origin: now) })
        }
    }
}
