import FuelGaugeCore

enum ResetPreferences {
    static let codexEnabled = "codexResetCreditsEnabled"
    static let claudeUsageEnabled = "claudeUsageEnabled"
    // Claude's typed resets are FuelGaugeCore's ClaudeResets, so the command reads the same values. The
    // weekly keys are the ones Fuel Gauge used before Fable resets existed.
    static let claudeCount = ClaudeResets.Kind.weekly.countKey
    static let claudeExpiry = ClaudeResets.Kind.weekly.expiryKey
    static let claudeFableCount = ClaudeResets.Kind.fable.countKey
    static let claudeFableExpiry = ClaudeResets.Kind.fable.expiryKey
    static let claudeCheckedAt = ClaudeResets.recordedAtKey
}
