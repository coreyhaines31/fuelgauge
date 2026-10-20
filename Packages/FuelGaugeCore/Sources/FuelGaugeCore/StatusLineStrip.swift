import Foundation

/// The line Fuel Gauge adds to Claude Code's status line: "⛽ 5h 55% out ~11:50a · wk 41% ok", colored by
/// verdict so a glance says whether to keep going.
public enum StatusLineStrip {
    public static func render(_ forecasts: [Forecast], now: Date = Date(), color: Bool = true) -> String? {
        let ordered = forecasts.sorted { (order($0.windowMinutes), $0.key) < (order($1.windowMinutes), $1.key) }
        guard !ordered.isEmpty else { return nil }
        let segments = ordered.map { forecast in
            let text = ForecastText.strip(forecast, now: now)
            return color ? paint(text, for: forecast.verdict) : text
        }
        return "⛽ " + segments.joined(separator: color ? dim(" · ") : " · ")
    }

    /// Shorter windows first: the 5-hour window is the one that interrupts work.
    private static func order(_ windowMinutes: Int?) -> Int {
        windowMinutes ?? Int.max
    }

    private static func paint(_ text: String, for verdict: Forecast.Verdict) -> String {
        let code = switch verdict {
        case .limitReached: "31"
        case .runsOut: "33"
        case .makesIt: "32"
        case .learning, .reset: "2"
        }
        return "\u{1B}[\(code)m\(text)\u{1B}[0m"
    }

    private static func dim(_ text: String) -> String {
        "\u{1B}[2m\(text)\u{1B}[0m"
    }
}
