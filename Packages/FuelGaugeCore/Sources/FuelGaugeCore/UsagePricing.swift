import Foundation

/// Standard, short-context API equivalents, not subscription charges or billing receipts.
/// Rates verified 2026-10-30 at developers.openai.com/api/docs/pricing and
/// platform.claude.com/docs/en/about-claude/pricing. Unknown models stay unpriced.
public enum UsagePricing {
    private struct Rate {
        let input: Double
        let output: Double
        let read: Double
        let write: Double
        let longWrite: Double
    }

    public static func cost(model: String, tokens: TokenUsage) -> Double? {
        guard let rate = rate(for: model) else { return nil }
        return (Double(tokens.input) * rate.input + Double(tokens.output) * rate.output
                + Double(tokens.cacheRead) * rate.read
                + Double(tokens.cacheWrite - tokens.cacheWriteLong) * rate.write
                + Double(tokens.cacheWriteLong) * rate.longWrite) / 1_000_000
    }

    private static func rate(for model: String) -> Rate? {
        let rates: [String: Rate] = [
            "gpt-6-astra": openAI(10, 50, 1),
            "gpt-6-sol": openAI(2, 10, 0.2),
            "gpt-6.1-sol": openAI(2, 10, 0.1),
            "gpt-6.1-terra": openAI(1, 5, 0.05),
            "gpt-6-luna": openAI(0.1, 0.5, 0.01),
            "gpt-5.6-sol": openAI(4, 20, 0.4),
            "gpt-5.3-codex": openAI(1.75, 14, 0.175),
            "gpt-5.4": openAI(2.5, 15, 0.25),
            "gpt-5.5": openAI(5, 30, 0.5),
            "claude-opus-5-5": claude(4, 20, 0.2),
            "claude-sonnet-5-5": claude(2, 10, 0.1),
            "claude-opus-5": claude(5, 25, 0.5),
            "claude-opus-4-8": claude(5, 25, 0.5),
            "claude-opus-4-7": claude(5, 25, 0.5),
            "claude-opus-4-6": claude(5, 25, 0.5),
            "claude-opus-4-5": claude(5, 25, 0.5),
            "claude-sonnet-5": claude(2, 10, 0.2),
            "claude-sonnet-4-6": claude(3, 15, 0.3),
            "claude-sonnet-4-5": claude(3, 15, 0.3),
            "claude-haiku-4-5": claude(1, 5, 0.1)
        ]
        if let exact = rates[model] { return exact }
        // Only dated snapshots may inherit a rate; unknown suffixes may denote a different model.
        for (name, rate) in rates where model.hasPrefix(name + "-") {
            let suffix = String(model.dropFirst(name.count + 1)).replacingOccurrences(of: "-", with: "")
            if suffix.count == 8 && suffix.allSatisfy(\.isNumber) { return rate }
        }
        return nil
    }

    private static func openAI(_ input: Double, _ output: Double, _ read: Double) -> Rate {
        Rate(input: input, output: output, read: read, write: input * 1.25, longWrite: input * 2.5)
    }

    private static func claude(_ input: Double, _ output: Double, _ read: Double) -> Rate {
        Rate(input: input, output: output, read: read, write: input * 1.25, longWrite: input * 2)
    }
}
