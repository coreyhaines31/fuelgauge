import Foundation
@testable import FuelGaugeCore
import Testing

@Suite struct CodexLogReaderTests {
    @Test func readsEveryWindowFromTokenCountEvents() throws {
        let root = temporaryFolder()
        let day = root.appending(path: "2026/10/13")
        try FileManager.default.createDirectory(at: day, withIntermediateDirectories: true)
        let file = day.appending(path: "rollout.jsonl")
        try FileManager.default.copyItem(at: try sample("codex-session.jsonl"), to: file)

        var reader = CodexLogReader(root: root)
        let now = try Date("2026-10-14T00:00:00Z", strategy: .iso8601)
        let readings = reader.poll(now: now)

        #expect(readings.count == 3)
        #expect(readings.map(\.limit) == ["codex-10080", "codex-300", "codex-10080"])
        #expect(readings.map(\.usedPercent) == [9, 12, 10])
        #expect(readings[1].resetsAt == Date(timeIntervalSince1970: 1_792_530_000))
        #expect(reader.poll(now: now).isEmpty, "a second poll reads only new lines")
    }

    @Test func leavesAHalfWrittenLineForTheNextPoll() throws {
        let root = temporaryFolder()
        let file = root.appending(path: "rollout.jsonl")
        let line = #"{"timestamp":"2026-10-13T18:40:00Z","payload":{"rate_limits":"#
            + #"{"primary":{"used_percent":5,"window_minutes":300,"resets_at":1792530000}}}}"#
        try Data(line.prefix(40).utf8).write(to: file)
        var reader = CodexLogReader(root: root)
        let now = try Date("2026-10-14T00:00:00Z", strategy: .iso8601)
        #expect(reader.poll(now: now).isEmpty)

        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((line.dropFirst(40) + "\n").utf8))
        try handle.close()
        #expect(reader.poll(now: now).map(\.usedPercent) == [5])
    }
}
