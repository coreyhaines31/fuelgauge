import Foundation
@testable import FuelGaugeCore
import Testing

struct UsageHistoryTests {
    private func event(_ id: String, at: Date = Date(), model: String = "claude-sonnet-4-6",
                       tokens: TokenUsage = TokenUsage(input: 100, output: 20)) -> UsageEvent {
        UsageEvent(id: id, provider: .claude, session: "session", project: "/project",
                   model: model, at: at, tokens: tokens)
    }

    @Test func tokenCategoriesDoNotDoubleCountReasoningOrLongCacheWrites() {
        let tokens = TokenUsage(input: 100, output: 50, cacheRead: 200,
                                cacheWrite: 80, cacheWriteLong: 30, reasoning: 40)
        #expect(tokens.total == 430)
        #expect(tokens.prompt == 380)
        #expect(tokens.cacheHitRate == 200.0 / 380)
        #expect(TokenUsage().cacheHitRate == nil)
    }

    @Test func partialPricesStayExplicit() {
        let summary = UsageSummary([event("one"), event("two", model: "unknown")])
        #expect(summary.unpricedEvents == 1)
        #expect(summary.costLabel.contains("unpriced"))
        #expect(summary.sessions == 1)
        #expect(UsageSummary([event("three", model: "unknown")]).costLabel == "Unavailable")
        #expect(UsagePricing.cost(model: "claude-sonnet-4-6-new", tokens: TokenUsage()) == nil)
    }

    @Test func standardRatesPriceSeparateCacheDurations() throws {
        let tokens = TokenUsage(input: 1_000_000, output: 1_000_000, cacheRead: 1_000_000,
                                cacheWrite: 2_000_000, cacheWriteLong: 1_000_000)
        let cost = try #require(UsagePricing.cost(model: "claude-sonnet-4-6-20260101", tokens: tokens))
        #expect(abs(cost - 28.05) < 0.000001)
    }

    @Test func streamingSnapshotsAndCopiedEventsCountOnce() {
        let records = [event("one"), event("one", tokens: TokenUsage(input: 100, output: 60)), event("two")]
        let unique = UsageHistory.deduplicate(records)
        #expect(unique.count == 2)
        #expect(UsageSummary(unique).tokens.output == 80)
    }

    @Test func rangesUseLocalDaysAndExcludeTheEndBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 12)))
        let interval = UsagePeriod.week.interval(now: now, calendar: calendar)
        let previous = UsagePeriod.week.previousInterval(now: now, calendar: calendar)
        #expect(calendar.component(.hour, from: interval.start) == 0)
        #expect(calendar.component(.hour, from: previous.end) == 12)
        #expect(calendar.dateComponents([.day], from: previous.start, to: interval.start).day == 7)
        let records = [event("start", at: interval.start), event("end", at: interval.end)]
        #expect(UsageHistory.select(records, interval: interval).map(\.id) == ["start"])
    }
}
