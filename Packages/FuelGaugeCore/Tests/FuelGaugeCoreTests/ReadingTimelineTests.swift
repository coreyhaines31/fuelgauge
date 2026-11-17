import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ReadingTimelineTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func reading(_ used: Double, _ minutes: Double, resetOffset: Double = 0) -> Reading {
        Reading(provider: .claude, limit: "weekly", windowMinutes: 10080, usedPercent: used,
                resetsAt: now.addingTimeInterval(86400 + resetOffset), at: now.addingTimeInterval(minutes * 60))
    }

    @Test func alternatingCachesDoNotCountTheSameConsumptionTwice() {
        let timeline = ReadingTimeline([reading(30, -30), reading(40, -20), reading(32, -19),
                                        reading(40, -18), reading(42, 0)], now: now)
        #expect(timeline.segments.count == 1)
        #expect(timeline.intervals.reduce(0) { $0 + $1.consumed } == 12)
        #expect(!timeline.hasConflict)
    }

    @Test func unresolvedContradictionsDoNotBecomeFreshLowerUsage() {
        let timeline = ReadingTimeline([reading(40, -5), reading(32, 0)], now: now)
        #expect(timeline.segments.last?.last?.usedPercent == 40)
        #expect(timeline.segments.last?.last?.at == now.addingTimeInterval(-300))
        #expect(timeline.hasConflict)
    }

    @Test func sustainedCorrectionsAndResetsStartNewBaselines() {
        let timeline = ReadingTimeline([reading(80, -40), reading(20, -30), reading(22, -20),
                                        reading(25, -10), reading(1, 0, resetOffset: 86400)], now: now)
        #expect(timeline.segments.count == 3)
        #expect(timeline.intervals.reduce(0) { $0 + $1.consumed } == 3)
        #expect(!timeline.hasConflict)
    }

    @Test func missingHoursAreNotQuietHours() {
        let rising = ReadingTimeline([reading(20, -600), reading(25, 0)], now: now)
        #expect(rising.intervals.isEmpty)
        let quiet = ReadingTimeline([reading(20, -600), reading(20, 0)], now: now)
        #expect(quiet.intervals.first?.hours == 10)
        let capped = ReadingTimeline([reading(100, -600), reading(100, 0)], now: now)
        #expect(capped.intervals.isEmpty)
    }

    @Test func rejectsInvalidAndFutureValuesAndResolvesTiesDeterministically() {
        let timeline = ReadingTimeline([reading(30, -20), reading(40, 0), reading(32, 0),
                                        reading(.nan, -1), reading(-1, -2), reading(90, 1)], now: now)
        #expect(timeline.segments.last?.last?.usedPercent == 40)
        #expect(!timeline.hasConflict)
    }
}
