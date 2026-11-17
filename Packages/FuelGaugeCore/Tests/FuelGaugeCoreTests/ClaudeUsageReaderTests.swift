import Foundation
@testable import FuelGaugeCore
import Testing

struct ClaudeUsageReaderTests {
    private func withCLI(_ script: String, check: (URL) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let executable = folder.appending(path: "claude")
        try Data(("#!/bin/bash\n" + script).utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        try check(executable)
    }

    @Test func asksForUsageWithHooksAndToolsOff() throws {
        try withCLI(#"""
        [[ "$*" == *'--settings {"disableAllHooks":true}'* && "$*" == *'--strict-mcp-config'* ]] || exit 1
        read -r initialize
        [[ "$initialize" == *'"subtype":"initialize"'* ]] || exit 1
        printf '%s\n' '{"type":"system","subtype":"init"}'
        printf '%s\n' '{"type":"control_response","response":{"subtype":"success","request_id":"fuelgauge-init"}}'
        read -r usage
        [[ "$usage" == *'"subtype":"get_usage"'* && "$usage" == *'"skip_behaviors":true'* ]] || exit 1
        printf '%s' '{"type":"control_response","response":{"subtype":"success","request_id":"fuelgauge-usage",'
        printf '%s' '"response":{"rate_limits":{"limits":[{"kind":"weekly_scoped","percent":36,'
        printf '%s\n' '"resets_at":"2026-11-20T21:00:00Z","scope":{"model":{"display_name":"Fable"}}}]}}}}'
        read -r finish
        """#) { executable in
            let usage = ClaudeUsageReader(executable: executable, timeout: 5).read()
            #expect(usage?.model(named: "Fable")?.usedPercent == 36)
        }
    }

    @Test func errorReplyIsNil() throws {
        try withCLI(#"""
        read -r initialize
        printf '%s\n' '{"type":"control_response","response":{"subtype":"success","request_id":"fuelgauge-init"}}'
        read -r usage
        printf '%s\n' '{"type":"control_response","response":{"subtype":"error","request_id":"fuelgauge-usage"}}'
        read -r finish
        """#) { executable in
            #expect(ClaudeUsageReader(executable: executable, timeout: 5).read() == nil)
        }
    }

    @Test func timeoutEarlyExitAndMissingExecutable() throws {
        #expect(ClaudeUsageReader(executable: URL(filePath: "/nonexistent/claude")).read() == nil)
        try withCLI("exit 0") { executable in
            #expect(ClaudeUsageReader(executable: executable, timeout: 1).read() == nil)
        }
        try withCLI("read -r initialize\nread -r wait") { executable in
            let start = Date()
            #expect(ClaudeUsageReader(executable: executable, timeout: 0.2).read() == nil)
            #expect(Date().timeIntervalSince(start) < 3)
        }
    }
}
