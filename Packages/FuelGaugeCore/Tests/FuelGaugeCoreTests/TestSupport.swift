import Foundation
@testable import FuelGaugeCore
import Testing

func sample(_ name: String) throws -> URL {
    try #require(Bundle.module.url(forResource: "Samples/\(name)", withExtension: nil))
}

func temporaryFolder() -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "FuelGaugeTests-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
