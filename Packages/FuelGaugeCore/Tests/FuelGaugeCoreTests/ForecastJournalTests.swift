import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ForecastJournalTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func reading(_ hours: Double, used: Double, reset: Double = 72) -> Reading {
        Reading(provider: .codex, limit: "weekly", windowMinutes: 10080, usedPercent: used,
                resetsAt: now.addingTimeInterval(reset * 3600), at: now.addingTimeInterval(hours * 3600))
    }

    var history: [Reading] { [reading(-4, used: 20), reading(0, used: 24)] }

    func journal() throws -> ForecastJournal {
        var result = ForecastJournal()
        let forecast = try #require(ForecastEngine.forecast(for: history, now: now))
        result.update(forecasts: [forecast], readings: history, now: now, appVersion: "test")
        return result
    }

    @Test func freezesPredictionsAndDeduplicatesWithinTheHour() throws {
        var journal = try journal()
        let first = try #require(journal.records.first)
        let later = now.addingTimeInterval(60)
        let changed = history + [reading(1.0 / 60, used: 60)]
        journal.update(forecasts: ForecastEngine.forecasts(from: changed, now: later),
                       readings: changed, now: later, appVersion: "new-version")
        #expect(journal.records == [first])
        #expect(first.targets[0].adaptive?.usage(at: first.targets[0].at, target: first.targets[0].at) == 25)
    }

    @Test func scoresAtTheObservationTimeAndNeverRewritesAnOutcome() throws {
        var journal = try journal()
        let actual = reading(1.1, used: 27)
        journal.update(forecasts: [], readings: history + [actual], now: actual.at, appVersion: "test")
        let target = journal.records[0].targets[0]
        #expect(target.outcome == .observed)
        #expect(target.actual == actual)
        #expect(target.receivedAt == actual.at)
        let expected = try #require(target.adaptive?.usage(at: actual.at, target: target.at))
        #expect(abs(expected - 25.1) < 0.001)
        journal.update(forecasts: [], readings: history + [reading(1.1, used: 90)],
                       now: now.addingTimeInterval(7200), appVersion: "test")
        #expect(journal.records[0].targets[0] == target)
    }

    @Test func sleepAndLateBackfillCannotManufactureOutcomes() throws {
        var journal = try journal()
        journal.update(forecasts: [], readings: history + [reading(1, used: 25)],
                       now: now.addingTimeInterval(2 * 3600), appVersion: "test")
        #expect(journal.records[0].targets[0].outcome == .missing)
        #expect(journal.records[0].targets[1].outcome == .pending)
    }

    @Test func excludesResetsCorrectionsAndUnresolvedConflicts() throws {
        let cases: [([Reading], ForecastRecord.Outcome)] = [
            ([reading(1, used: 2, reset: 100)], .changed),
            ([reading(0.5, used: 2), reading(1, used: 3)], .changed),
            ([reading(1, used: 2)], .unreliable)
        ]
        for (extra, expected) in cases {
            var journal = try journal()
            journal.update(forecasts: [], readings: history + extra,
                           now: now.addingTimeInterval(4501), appVersion: "test")
            #expect(journal.records[0].targets[0].outcome == expected)
        }
    }

    @Test func clipsTheEstimateAtExhaustionInsteadOfSmoothingPastIt() throws {
        let data = [reading(-4, used: 50), reading(0, used: 96)]
        let forecast = try #require(ForecastEngine.forecast(for: data, now: now))
        let target = now.addingTimeInterval(1200)
        let estimate = try #require(ForecastRecord.Estimate(forecast, target: target, origin: now))
        #expect(abs(estimate.usage(at: target, target: target) - 99.833333) < 0.001)
        #expect(estimate.usage(at: now.addingTimeInterval(1500), target: target) == 100)
    }

    @Test func skipsTargetsBeyondResetAndPrunesOldRecords() throws {
        let data = [reading(-4, used: 20, reset: 6), reading(0, used: 24, reset: 6)]
        var journal = ForecastJournal()
        journal.update(forecasts: ForecastEngine.forecasts(from: data, now: now),
                       readings: data, now: now, appVersion: "test")
        #expect(journal.records[0].targets.map(\.outcome) == [.pending, .beyondReset, .beyondReset])
        journal.update(forecasts: [], readings: [], now: now.addingTimeInterval(61 * 86400), appVersion: "test")
        #expect(journal.records.isEmpty)
    }
}
