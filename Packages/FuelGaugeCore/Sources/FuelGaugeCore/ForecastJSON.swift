import Foundation

/// The shape of `fuelgauge status --json`: stable snake_case keys for scripts and agents.
public struct ForecastJSON: Encodable {
    public let tool: String
    public let window: String
    public let usedPercent: Double
    public let resetsAt: Date
    public let verdict: String
    public let runsOutAt: Date?
    public let runsOutEarliest: Date?
    public let runsOutLatest: Date?
    public let projectedPercentAtReset: Double?
    public let ratePerHour: Double?
    public let budgetPerHour: Double?
    public let lastReadingAt: Date
    public let summary: String

    public init(_ forecast: Forecast, now: Date = Date()) {
        tool = forecast.key.provider.rawValue
        window = forecast.windowName.lowercased()
        usedPercent = forecast.usedPercent
        resetsAt = forecast.resetsAt
        ratePerHour = forecast.ratePerHour
        budgetPerHour = forecast.budgetPerHour
        lastReadingAt = forecast.lastReadingAt
        summary = ForecastText.headline(forecast, now: now)
        switch forecast.verdict {
        case .learning:
            verdict = "learning"
            projectedPercentAtReset = nil
        case .limitReached:
            verdict = "out"
            projectedPercentAtReset = 100
        case .reset:
            verdict = "reset"
            projectedPercentAtReset = nil
        case .makesIt(let projected):
            verdict = "makes_it"
            projectedPercentAtReset = projected
        case .runsOut(let at, let earliest, let latest):
            verdict = "runs_out"
            projectedPercentAtReset = 100
            (runsOutAt, runsOutEarliest, runsOutLatest) = (at, earliest, latest)
            return
        }
        (runsOutAt, runsOutEarliest, runsOutLatest) = (nil, nil, nil)
    }

    public static func encode(_ forecasts: [Forecast], now: Date = Date()) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(forecasts.map { ForecastJSON($0, now: now) })
    }
}
