import Foundation
@testable import FuelGaugeCore
import Testing

struct UsageLogTests {
    private let timestamp = "2026-10-30T12:00:00Z"

    private func codex(input: Int, output: Int, cached: Int = 0, lastInput: Int? = nil) -> Data {
        Data("""
        {"type":"event_msg","timestamp":"\(timestamp)","payload":{"type":"token_count","info":{
        "total_token_usage":{"input_tokens":\(input),"output_tokens":\(output),"cached_input_tokens":\(cached)},
        "last_token_usage":{"input_tokens":\(lastInput ?? input),"output_tokens":\(output)}}}}
        """.replacingOccurrences(of: "\n", with: "").utf8)
    }

    @Test func codexUsesDeltasAndIgnoresRepeatedCounters() throws {
        var parser = UsageLogParser(session: "test")
        _ = parser.parse(Data(#"{"type":"turn_context","payload":{"model":"gpt-6.1-sol","cwd":"/repo"}}"#.utf8),
                         provider: .codex)
        let firstResult = parser.parse(codex(input: 100, output: 10), provider: .codex)
        let first = try #require(firstResult)
        #expect(first.tokens.total == 110)
        #expect(parser.parse(codex(input: 100, output: 10), provider: .codex) == nil)
        let secondResult = parser.parse(codex(input: 300, output: 30, cached: 150), provider: .codex)
        let second = try #require(secondResult)
        #expect(second.tokens.input == 50)
        #expect(second.tokens.cacheRead == 150)
        #expect(second.tokens.output == 20)
        #expect(second.project == "/repo")
        #expect(second.model == "gpt-6.1-sol")
        let resetResult = parser.parse(codex(input: 20, output: 5), provider: .codex)
        let reset = try #require(resetResult)
        #expect(reset.tokens.total == 25)
    }

    @Test func firstCodexCounterDoesNotImportUnobservedHistory() throws {
        var parser = UsageLogParser(session: "fork")
        let eventResult = parser.parse(codex(input: 1000, output: 10, lastInput: 25), provider: .codex)
        let event = try #require(eventResult)
        #expect(event.tokens.input == 25)
    }

    @Test func claudeKeepsCachesSeparateAndDeduplicatesStreaming() throws {
        var parser = UsageLogParser(session: "test")
        func line(_ output: Int) -> Data {
            Data("""
            {"type":"assistant","sessionId":"session","requestId":"request","timestamp":"\(timestamp)",
            "cwd":"/repo","message":{"id":"message","model":"claude-sonnet-4-6","usage":{
            "input_tokens":10,"output_tokens":\(output),"cache_read_input_tokens":100,
            "cache_creation_input_tokens":50,"cache_creation":{"ephemeral_1h_input_tokens":20}}}}
            """.utf8)
        }
        let firstResult = parser.parse(line(10), provider: .claude)
        let first = try #require(firstResult)
        let secondResult = parser.parse(line(30), provider: .claude)
        let second = try #require(secondResult)
        let summary = UsageSummary(UsageHistory.deduplicate([first, second]))
        #expect(summary.tokens.total == 190)
        #expect(summary.tokens.cacheWriteLong == 20)
    }

    @Test func scannerResumesPartialLinesAndSurvivesRestartAndTruncation() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "session.jsonl")
        let cache = folder.appending(path: "cache.json")
        let roots = [UsageLogScanner.Root(provider: .codex, url: folder)]
        let now = try Date("2026-10-30T14:00:00Z", strategy: .iso8601)
        let line = codex(input: 100, output: 10) + Data([10])
        try line.dropLast(4).write(to: file)
        var scanner = UsageLogScanner(roots: roots, cacheURL: cache)
        #expect(scanner.scan(enabled: [.codex], now: now).isEmpty)
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: line.suffix(4))
        try handle.close()
        #expect(scanner.scan(enabled: [.codex], now: now).count == 1)
        scanner = UsageLogScanner(roots: roots, cacheURL: cache)
        #expect(scanner.scan(enabled: [.codex], now: now).count == 1)
        #expect(scanner.scan(enabled: [], now: now).isEmpty)
        try (codex(input: 2, output: 1) + Data([10])).write(to: file, options: .atomic)
        #expect(UsageSummary(scanner.scan(enabled: [.codex], now: now)).tokens.total == 3)
        #expect(scanner.warnings.isEmpty)
    }
}
