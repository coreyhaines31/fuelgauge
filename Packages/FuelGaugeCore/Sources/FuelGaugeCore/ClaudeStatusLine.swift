import Foundation

/// Claude Code runs its status line command after each message and passes it JSON on stdin, including
/// `rate_limits.five_hour` and `seven_day` for Pro and Max plans. `fuelgauge statusline` is that command:
/// it saves a reading from the JSON, then prints the forecast strip.
public enum ClaudeStatusLine {
    /// The readings in one status line input. Empty when the plan has no limits or before the first reply.
    public static func readings(from input: Data, at now: Date = Date()) -> [Reading] {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: input),
              let limits = payload.rateLimits else { return [] }
        let windows: [NamedWindow] = [
            NamedWindow(name: "five_hour", minutes: 300, window: limits.fiveHour),
            NamedWindow(name: "seven_day", minutes: 10080, window: limits.sevenDay),
            NamedWindow(name: "spend_limit", minutes: nil, window: limits.spendLimit)
        ]
        return windows.compactMap { named in
            guard let window = named.window, let used = window.usedPercentage, let resetsAt = window.resetsAt else {
                return nil
            }
            return Reading(
                provider: .claude, limit: named.name, windowMinutes: named.minutes,
                usedPercent: used, resetsAt: Date(timeIntervalSince1970: resetsAt), at: now
            )
        }
    }

    private struct NamedWindow {
        let name: String
        let minutes: Int?
        let window: Window?
    }

    private struct Payload: Decodable {
        let rateLimits: Limits?

        enum CodingKeys: String, CodingKey {
            case rateLimits = "rate_limits"
        }
    }

    private struct Limits: Decodable {
        let fiveHour: Window?
        let sevenDay: Window?
        let spendLimit: Window?

        enum CodingKeys: String, CodingKey {
            case fiveHour = "five_hour", sevenDay = "seven_day", spendLimit = "spend_limit"
        }
    }

    private struct Window: Decodable {
        let usedPercentage: Double?
        let resetsAt: Double?

        enum CodingKeys: String, CodingKey {
            case usedPercentage = "used_percentage", resetsAt = "resets_at"
        }
    }
}
