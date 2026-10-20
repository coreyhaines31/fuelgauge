import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct ReadingStoreTests {
    let later = Date(timeIntervalSince1970: 1_800_100_000)

    private func reading(_ used: Double, at minutes: Double, limit: String = "five_hour") -> Reading {
        Reading(
            provider: .claude, limit: limit, windowMinutes: 300, usedPercent: used,
            resetsAt: Date(timeIntervalSince1970: 1_800_000_000),
            at: Date(timeIntervalSince1970: 1_799_990_000 + minutes * 60)
        )
    }

    @Test func skipsRepeatsButKeepsAHeartbeat() throws {
        let store = ReadingStore(folder: temporaryFolder())
        try store.append([reading(10, at: 0), reading(10, at: 1), reading(11, at: 2), reading(11, at: 13)], now: later)
        try store.append([reading(11, at: 14)], now: later)
        let loaded = store.load(since: .distantPast)
        #expect(loaded.map(\.usedPercent) == [10, 11, 11])
    }

    @Test func keepsLimitsApart() throws {
        let store = ReadingStore(folder: temporaryFolder())
        try store.append([reading(10, at: 0), reading(40, at: 0, limit: "seven_day")], now: later)
        #expect(store.load(since: .distantPast).count == 2)
        #expect(store.load(since: .distantPast, provider: .codex).isEmpty)
    }

    @Test func dropsReadingsFromTheFuture() throws {
        let store = ReadingStore(folder: temporaryFolder())
        let now = Date(timeIntervalSince1970: 1_799_990_000)
        try store.append([reading(50, at: 24 * 60)], now: now)
        try store.append([reading(10, at: 0)], now: now)
        #expect(store.load(since: .distantPast).map(\.usedPercent) == [10])
    }
}
