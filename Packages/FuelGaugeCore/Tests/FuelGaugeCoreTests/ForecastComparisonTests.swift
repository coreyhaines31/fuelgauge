import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ForecastComparisonTests {
    let fixtures = ForecastJournalTests()

    @Test func comparesAtTheActualReadingTimeRatherThanTheNominalTarget() throws {
        var journal = try fixtures.journal()
        let actual = fixtures.reading(1.1, used: 27)
        journal.update(forecasts: [], readings: fixtures.history + [actual], now: actual.at, appVersion: "new")
        let point = try #require(history(journal, now: actual.at).first)
        #expect(point.at == actual.at)
        #expect(point.target.at == fixtures.now.addingTimeInterval(3600))
        #expect(abs(try #require(point.predicted) - 25.1) < 0.001)
        #expect(point.recent == point.predicted)
        #expect(abs(try #require(point.error) + 1.9) < 0.001)
        #expect(point.actual == actual)
        #expect(point.record.appVersion == "test")
        #expect(point.record.source.resetsAt == fixtures.reading(0, used: 24).resetsAt)
    }

    @Test func unavailableOutcomesNeverBecomeZeroOrObservedUsage() throws {
        let original = try #require(fixtures.journal().records.first)
        for outcome: ForecastRecord.Outcome in [.pending, .missing, .changed, .unreliable, .beyondReset] {
            var target = original.targets[0]
            target.outcome = outcome
            // Even contradictory cached data must not turn an excluded outcome into an observation.
            target.actual = fixtures.reading(1.1, used: 99)
            let point = ForecastComparison(record: original, target: target)
            #expect(point.actual == nil)
            #expect(point.error == nil)
            #expect(point.at == target.at)
            #expect(point.predicted == 25)
        }
    }

    @Test func anObservedReadingWithoutAnEstimateStaysVisibleAndUnscored() throws {
        let original = try #require(fixtures.journal().records.first)
        let target = ForecastRecord.Target(hours: 1, at: fixtures.now.addingTimeInterval(3600),
            adaptive: nil, recent: original.targets[0].recent, outcome: .observed,
            actual: fixtures.reading(1, used: 0))
        let point = ForecastComparison(record: original, target: target)
        #expect(point.predicted == nil)
        #expect(point.actual?.usedPercent == 0)
        #expect(point.recent == 25)
        #expect(point.error == nil)
    }

    @Test func keepsPendingAndBeyondResetTargetsWithoutInventingPredictions() throws {
        let readings = [fixtures.reading(-4, used: 20, reset: 6), fixtures.reading(0, used: 24, reset: 6)]
        var journal = ForecastJournal()
        journal.update(forecasts: ForecastEngine.forecasts(from: readings, now: fixtures.now),
                       readings: readings, now: fixtures.now, appVersion: "test")
        let points = history(journal, now: fixtures.now)
        #expect(points.map(\.target.hours) == [1, 6, 24])
        #expect(points.map(\.target.outcome) == [.pending, .beyondReset, .beyondReset])
        #expect(points[0].predicted == 25)
        #expect(points[1].predicted == nil)
        #expect(points[2].actual == nil)
        #expect(Set(points.map(\.id)).count == 3)
    }

    @Test func selectsOnlyThisLimitsLastThirtyDaysWithoutFutureIssues() throws {
        var journal = ForecastJournal()
        for offset in [-31.0, -30, -1, 0, 1] {
            let now = fixtures.now.addingTimeInterval(offset * 86400)
            let data = fixtures.history.map { reading in
                Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: reading.usedPercent,
                        resetsAt: now.addingTimeInterval(72 * 3600),
                        at: reading.at.addingTimeInterval(offset * 86400))
            }
            journal.update(forecasts: ForecastEngine.forecasts(from: data, now: now),
                           readings: data, now: now, appVersion: "test")
        }
        let points = history(journal, now: fixtures.now)
        #expect(points.count == 9)
        #expect(Set(points.map(\.record.issuedAt)).count == 3)
        #expect(points.map(\.at) == points.map(\.at).sorted())
        #expect(ForecastComparison.history(journal, key: .init(provider: .claude, limit: "weekly"),
                                           now: fixtures.now).isEmpty)
        #expect(history(ForecastJournal(), now: fixtures.now).isEmpty)
    }

    private func history(_ journal: ForecastJournal, now: Date) -> [ForecastComparison] {
        ForecastComparison.history(journal, key: .init(provider: .codex, limit: "weekly"), now: now)
    }
}
