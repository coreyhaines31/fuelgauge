import Foundation

/// Claude's per-model weekly allowances, like Fable's, from the structured usage Claude Code answers its
/// `get_usage` control request with. The status line doesn't carry them. Claude Code calls the request
/// experimental, so anything unexpected reads as "nothing known" rather than as zero.
public struct ClaudeUsage: Codable, Sendable, Equatable {
    public struct ModelAllowance: Codable, Sendable, Equatable {
        /// The server's label, like "Fable".
        public let name: String
        public let usedPercent: Double
        public let resetsAt: Date
        /// How much of the weekly limit this model's use took, when the server says. A reset for this model
        /// gives that much back.
        public let usedPercentOfWeekly: Double?
        /// The most of the weekly limit this model can take.
        public let allowancePercentOfWeekly: Double?

        public init(name: String, usedPercent: Double, resetsAt: Date, usedPercentOfWeekly: Double? = nil,
                    allowancePercentOfWeekly: Double? = nil) {
            self.name = name
            self.usedPercent = usedPercent
            self.resetsAt = resetsAt
            self.usedPercentOfWeekly = usedPercentOfWeekly
            self.allowancePercentOfWeekly = allowancePercentOfWeekly
        }

        public var limit: String { ModelLimit.limit(forModel: name) }
    }

    /// Empty when Claude answered and listed no per-model allowance for this account.
    public let models: [ModelAllowance]
    public let checkedAt: Date

    public init(models: [ModelAllowance], checkedAt: Date) {
        self.models = models
        self.checkedAt = checkedAt
    }

    /// Where the app keeps the last answer, so the `fuelgauge` command can show it too.
    public static var defaultURL: URL { Brand.supportFolder.appending(path: "claude-usage.json") }

    public static func load(from url: URL = defaultURL) -> ClaudeUsage? {
        (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(ClaudeUsage.self, from: $0) }
    }

    public func save(to url: URL = defaultURL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }

    public func model(named name: String) -> ModelAllowance? {
        models.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// One reading per allowance, for the store, so each one gets a forecast like any other limit.
    public func readings() -> [Reading] {
        models.map {
            Reading(provider: .claude, limit: $0.limit, windowMinutes: 10080, usedPercent: $0.usedPercent,
                    resetsAt: $0.resetsAt, at: checkedAt)
        }
    }

    /// Reads the `get_usage` response object. Nil when it has no plan limits (an API key, or no Claude plan).
    public static func decode(_ data: Data, at now: Date = Date()) -> ClaudeUsage? {
        guard let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let limits = response["rate_limits"] as? [String: Any] else { return nil }
        return ClaudeUsage(models: allowances(in: limits), checkedAt: now)
    }

    private static func allowances(in limits: [String: Any]) -> [ModelAllowance] {
        guard let rows = limits["limits"] as? [Any] else { return fallback(limits["model_scoped"]) }
        var shares: [Int: [String: Any]] = [:]
        for case let share as [String: Any] in limits["weekly_scoped_shares"] as? [Any] ?? [] {
            if let index = (share["limit_index"] as? NSNumber)?.intValue { shares[index] = share }
        }
        return rows.enumerated().compactMap { index, item in
            guard let row = item as? [String: Any], row["kind"] as? String == "weekly_scoped",
                  let scope = row["scope"] as? [String: Any], let model = scope["model"] as? [String: Any],
                  let name = cleanName(model["display_name"]),
                  let used = percent(row["percent"]), let resetsAt = date(row["resets_at"]) else { return nil }
            let share = shares[index]
            return ModelAllowance(name: name, usedPercent: used, resetsAt: resetsAt,
                                  usedPercentOfWeekly: percent(share?["used_percent_of_weekly"]),
                                  allowancePercentOfWeekly: percent(share?["allowance_percent_of_weekly"]))
        }
    }

    /// Claude Code's own projection of the same rows, for a reply without `limits`.
    private static func fallback(_ value: Any?) -> [ModelAllowance] {
        (value as? [Any] ?? []).compactMap { item in
            guard let row = item as? [String: Any], let name = cleanName(row["display_name"]),
                  let used = percent(row["utilization"]), let resetsAt = date(row["resets_at"]) else { return nil }
            return ModelAllowance(name: name, usedPercent: used, resetsAt: resetsAt)
        }
    }

    private static func cleanName(_ value: Any?) -> String? {
        guard let name = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty, name.count <= 40 else { return nil }
        return name
    }

    private static func percent(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let percent = number.doubleValue
        return percent.isFinite && percent >= 0 && percent <= 1000 ? percent : nil
    }

    /// ISO 8601 with any number of fractional digits ("2026-11-17T20:59:59.939604+00:00"), or epoch seconds.
    static func date(_ value: Any?) -> Date? {
        if let seconds = value as? NSNumber, CFGetTypeID(seconds) != CFBooleanGetTypeID() {
            return Date(timeIntervalSince1970: seconds.doubleValue)
        }
        guard var text = value as? String else { return nil }
        if let range = text.range(of: #"\.\d+"#, options: .regularExpression) { text.removeSubrange(range) }
        return try? Date(text, strategy: .iso8601)
    }
}

/// Limits scoped to one model, like Claude's Fable allowance, are stored as `seven_day_model_<name>`.
public enum ModelLimit {
    static let prefix = "seven_day_model_"

    public static func limit(forModel name: String) -> String {
        let slug = name.lowercased().map { $0.isASCII && ($0.isLetter || $0.isNumber) ? String($0) : "_" }.joined()
        return prefix + String(slug.prefix(24))
    }

    /// "Fable" for `seven_day_model_fable`; nil for other limits.
    public static func modelName(of limit: String) -> String? {
        guard limit.hasPrefix(prefix), limit.count > prefix.count else { return nil }
        return limit.dropFirst(prefix.count).split(separator: "_").map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
