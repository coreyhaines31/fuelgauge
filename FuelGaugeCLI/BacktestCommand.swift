import Foundation
import FuelGaugeCore

func backtest() -> Never {
    let now = Date()
    let days = Double(option("--days") ?? "7") ?? 7
    guard days.isFinite, days >= 1, days <= 56 else { fail("--days must be between 1 and 56") }
    let enabled = Tracking.enabled()
    let readings = store.load(since: now.addingTimeInterval(-(days * 86400 + ForecastEngine.historyDuration)))
        .filter { enabled.contains($0.provider) }
    let results = ForecastBacktest.run(readings, since: now.addingTimeInterval(-days * 86400), now: now)
    if wantsJSON {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(results) else { fail("couldn't encode the replay results") }
        FileHandle.standardOutput.write(data + Data("\n".utf8))
    } else {
        print("Historical replay · past \(Int(days)) days · errors in percentage points")
        print("Only observed outcomes in the same window are scored. Errors compare paired forecasts.")
        print("Replayed source timestamps may predate when readings were imported. Checkpoints overlap.")
        for result in results {
            print("\n\(result.tool)/\(result.limit) · \(result.horizonHours)h ahead")
            print("  Observed: \(result.eligible) · comparable: \(result.pairedForecasts)")
            print("  Forecasts: recent \(result.recentForecasts), adaptive \(result.adaptiveForecasts)"
                  + " · learned schedule: \(result.scheduledForecasts)")
            if let old = result.recentMAE, let new = result.adaptiveMAE {
                print(String(format: "  Mean absolute error: recent %.2f · adaptive %.2f", old, new))
                print("  Missed exhaustion: recent \(result.recentMissedExhaustions)"
                      + " · adaptive \(result.adaptiveMissedExhaustions)")
                print("  Predicted exhaustion too early: recent \(result.recentEarlyExhaustions)"
                      + " · adaptive \(result.adaptiveEarlyExhaustions)")
            } else {
                print("  Not enough comparable observations.")
            }
        }
    }
    exit(0)
}
