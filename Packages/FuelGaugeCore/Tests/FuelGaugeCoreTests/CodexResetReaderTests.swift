import Foundation
@testable import FuelGaugeCore
import Testing

struct CodexResetReaderTests {
    private func withServer(_ script: String, check: (URL) throws -> Void) throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let executable = folder.appending(path: "codex")
        try Data(("#!/bin/bash\n" + script).utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        try check(executable)
    }

    @Test func handshakeAndCount() throws {
        try withServer(#"""
        read -r initialize
        [[ "$initialize" == *'initialize'* ]] || exit 1
        printf '%s\n' '{"id":1,"result":{}}'
        read -r initialized
        read -r request
        [[ "$request" == *'account/rateLimits/read'* ]] || exit 1
        printf '%s\n' '{"method":"notification"}'
        printf '%s' '{"id":2,"result":{"rateLimitResetCredits":'
        printf '%s\n' '{"availableCount":2,"credits":null}}}'
        read -r finish
        """#) { executable in
            #expect(CodexResetReader(executable: executable).read()?.availableCount == 2)
        }
    }

    @Test func timeout() throws {
        try withServer("read -r initialize\nread -r wait") { executable in
            let start = Date()
            #expect(CodexResetReader(executable: executable, timeout: 0.2).read() == nil)
            #expect(Date().timeIntervalSince(start) < 3)
        }
    }

    @Test func errorsAndMissingExecutable() throws {
        #expect(CodexResetReader(executable: URL(filePath: "/nonexistent/codex")).read() == nil)
        try withServer(#"""
        read -r initialize
        printf '%s\n' '{"id":1,"error":{"message":"unsupported"}}'
        read -r finish
        """#) { executable in
            #expect(CodexResetReader(executable: executable).read() == nil)
        }
    }
}
