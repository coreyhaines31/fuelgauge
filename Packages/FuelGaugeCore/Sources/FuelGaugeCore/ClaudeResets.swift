import Foundation

/// The limit resets saved on a Claude account, as the person recorded them in Settings. Claude Code doesn't
/// hand the balance to other apps, so these are manual. The app writes them to its defaults; the `fuelgauge`
/// command reads the same defaults.
public struct ClaudeResets: Equatable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case fable, weekly

        public var name: String {
            switch self {
            case .fable: "Fable"
            case .weekly: "Weekly"
            }
        }

        /// What one reset does, in the same terms as Claude's settings.
        public var explanation: String {
            switch self {
            case .fable: "Refills Fable and gives back what Fable used this week"
            case .weekly: "Resets your whole week"
            }
        }

        /// For mid-sentence use: "Fable", "weekly".
        public var phrase: String { self == .fable ? "Fable" : "weekly" }

        /// "3 Fable resets", "1 weekly reset".
        public func count(_ count: Int) -> String {
            "\(count) \(phrase) reset" + (count == 1 ? "" : "s")
        }

        // The weekly keys are the ones Fuel Gauge used before Fable resets existed, when every Claude reset
        // reset the whole week.
        var countKey: String { self == .fable ? "claudeFableResetCount" : "claudeResetCount" }
        var expiryKey: String { self == .fable ? "claudeFableResetExpiry" : "claudeResetExpiry" }
    }

    public struct Balance: Equatable, Sendable {
        public var available: Int
        /// When the saved resets of this kind lapse unused. Claude gives one date per kind.
        public var expiresAt: Date?

        public init(available: Int = 0, expiresAt: Date? = nil) {
            self.available = available
            self.expiresAt = expiresAt
        }
    }

    public static let recordedAtKey = "claudeResetsCheckedAt"
    /// How far ahead an expiry is worth a warning.
    public static let warningWindow: TimeInterval = 7 * 86400

    public var fable: Balance
    public var weekly: Balance
    /// When the person last recorded the balance; nil when they never have.
    public var recordedAt: Date?

    public init(fable: Balance = Balance(), weekly: Balance = Balance(), recordedAt: Date? = nil) {
        self.fable = fable
        self.weekly = weekly
        self.recordedAt = recordedAt
    }

    public subscript(kind: Kind) -> Balance {
        get { kind == .fable ? fable : weekly }
        set { if kind == .fable { fable = newValue } else { weekly = newValue } }
    }

    public static func load(from defaults: UserDefaults = Tracking.defaults) -> ClaudeResets {
        func balance(_ kind: Kind) -> Balance {
            let expiry = defaults.double(forKey: kind.expiryKey)
            return Balance(available: max(0, defaults.integer(forKey: kind.countKey)),
                           expiresAt: expiry > 0 ? Date(timeIntervalSince1970: expiry) : nil)
        }
        let recorded = defaults.double(forKey: recordedAtKey)
        return ClaudeResets(fable: balance(.fable), weekly: balance(.weekly),
                            recordedAt: recorded > 0 ? Date(timeIntervalSince1970: recorded) : nil)
    }

    public func save(to defaults: UserDefaults = Tracking.defaults) {
        for kind in Kind.allCases {
            let balance = self[kind]
            defaults.set(balance.available, forKey: kind.countKey)
            let expiry = balance.available > 0 ? balance.expiresAt?.timeIntervalSince1970 ?? 0 : 0
            defaults.set(expiry, forKey: kind.expiryKey)
        }
        defaults.set(recordedAt?.timeIntervalSince1970 ?? 0, forKey: Self.recordedAtKey)
    }

    /// Resets of this kind that can still be used. A past expiry means the recorded count is out of date.
    public func usable(_ kind: Kind, now: Date = Date()) -> Int {
        guard recordedAt != nil else { return 0 }
        let balance = self[kind]
        if let expiry = balance.expiresAt, expiry <= now { return 0 }
        return balance.available
    }

    /// "3 Fable resets", or "Recheck Fable resets" once the recorded expiry has passed.
    public func summary(_ kind: Kind, now: Date = Date()) -> String {
        let balance = self[kind]
        if balance.available > 0, let expiry = balance.expiresAt, expiry <= now {
            return "Recheck \(kind.phrase) resets"
        }
        return balance.available == 0 ? "No \(kind.phrase) resets" : kind.count(balance.available)
    }

    /// "All expire Mar 8" or "Expires Dec 15", for a balance with an expiry.
    public func expiry(_ kind: Kind, now: Date = Date()) -> String? {
        let balance = self[kind]
        guard balance.available > 0, let expiry = balance.expiresAt else { return nil }
        let when = Self.date(expiry, now: now)
        if expiry <= now { return "Set to expire \(when)" }
        return (balance.available == 1 ? "Expires " : "All expire ") + when
    }

    /// Resets about to lapse unused: "3 Fable resets expire Sun 11:59p if unused".
    public func warnings(now: Date = Date()) -> [(kind: Kind, text: String)] {
        guard recordedAt != nil else { return [] }
        return Kind.allCases.compactMap { kind in
            let balance = self[kind]
            guard balance.available > 0, let expiry = balance.expiresAt, expiry > now,
                  expiry.timeIntervalSince(now) <= Self.warningWindow else { return nil }
            let verb = balance.available == 1 ? "expires" : "expire"
            return (kind, "\(kind.count(balance.available)) \(verb) \(ForecastText.time(expiry, now: now)) if unused")
        }
    }

    /// "Mar 8, 2027" when it's not this year, else "Dec 15".
    static func date(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = sameYear ? "MMM d" : "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
