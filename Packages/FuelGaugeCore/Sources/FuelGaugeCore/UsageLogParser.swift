import CryptoKit
import Foundation

struct UsageLogParser: Codable, Sendable {
    var session: String
    var project = "Unknown project"
    var model = "Unknown model"
    var cumulative: [String: Int64]?

    mutating func parse(_ data: Data, provider: Provider) -> UsageEvent? {
        guard let row = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if provider == .claude { return claude(row) }
        return codex(row)
    }

    private mutating func claude(_ row: [String: Any]) -> UsageEvent? {
        guard row["type"] as? String == "assistant", let message = row["message"] as? [String: Any],
              let usage = message["usage"] as? [String: Any], let at = Self.date(row["timestamp"]),
              let messageID = message["id"] as? String, !messageID.isEmpty else { return nil }
        let session = row["sessionId"] as? String ?? session
        let request = row["requestId"] as? String ?? session
        let cache = usage["cache_creation"] as? [String: Any] ?? [:]
        let write = Self.count(usage, "cache_creation_input_tokens")
        let tokens = TokenUsage(input: Self.count(usage, "input_tokens"), output: Self.count(usage, "output_tokens"),
                                cacheRead: Self.count(usage, "cache_read_input_tokens"), cacheWrite: write,
                                cacheWriteLong: min(write, Self.count(cache, "ephemeral_1h_input_tokens")))
        guard tokens.total > 0 else { return nil }
        return UsageEvent(id: "claude/\(request)/\(messageID)", provider: .claude, session: session,
                          project: row["cwd"] as? String ?? project, model: message["model"] as? String ?? model,
                          at: at, tokens: tokens)
    }

    private mutating func codex(_ row: [String: Any]) -> UsageEvent? {
        guard let payload = row["payload"] as? [String: Any] else { return nil }
        let type = row["type"] as? String
        if type == "session_meta" {
            session = payload["id"] as? String ?? session
            project = payload["cwd"] as? String ?? project
        }
        if type == "turn_context" {
            model = payload["model"] as? String ?? "Unknown model"
            project = payload["cwd"] as? String ?? project
        }
        guard type == "event_msg", payload["type"] as? String == "token_count",
              let info = payload["info"] as? [String: Any],
              let total = info["total_token_usage"] as? [String: Any],
              let at = Self.date(row["timestamp"]) else { return nil }
        let keys = ["input_tokens", "output_tokens", "cached_input_tokens", "cache_write_input_tokens",
                    "reasoning_output_tokens"]
        let current = Dictionary(uniqueKeysWithValues: keys.map { ($0, Self.count(total, $0)) })
        if current == cumulative { return nil }
        let previous = cumulative
        cumulative = current
        let last = info["last_token_usage"] as? [String: Any]
        let reset = previous.map { prior in keys.contains { current[$0, default: 0] < prior[$0, default: 0] } } ?? true
        let delta = Dictionary(uniqueKeysWithValues: keys.map { key in
            (key, reset ? (last.map { Self.count($0, key) } ?? current[key, default: 0])
             : max(0, current[key, default: 0] - (previous?[key] ?? 0)))
        })
        let input = delta["input_tokens", default: 0]
        let read = min(input, delta["cached_input_tokens", default: 0])
        let write = min(input - read, delta["cache_write_input_tokens", default: 0])
        let output = delta["output_tokens", default: 0]
        let reasoning = delta["reasoning_output_tokens", default: 0]
        let tokens = TokenUsage(input: input - read - write,
                                output: info["last_usage_includes_reasoning"] as? Bool == false
                                    ? output + reasoning : output,
                                cacheRead: read, cacheWrite: write, reasoning: reasoning)
        guard tokens.total > 0 else { return nil }
        // Copied history in a fork has the same timestamp and cumulative counters.
        let counters = keys.map { current[$0, default: 0].description }.joined(separator: "/")
        let identity = "\(row["timestamp"] ?? "")/\(counters)"
        let digest = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        return UsageEvent(id: "codex/\(digest)", provider: .codex, session: session,
                          project: project, model: model, at: at, tokens: tokens)
    }

    private static func count(_ object: [String: Any], _ key: String) -> Int64 {
        guard let number = object[key] as? NSNumber else { return 0 }
        let value = number.doubleValue
        // Reject malformed counters and leave headroom for aggregation.
        guard value.isFinite, value >= 0, value <= 1_000_000_000_000 else { return 0 }
        return Int64(value)
    }

    private static func date(_ value: Any?) -> Date? {
        guard let text = value as? String else { return nil }
        return (try? Date(text, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
            ?? (try? Date(text, strategy: .iso8601))
    }
}
