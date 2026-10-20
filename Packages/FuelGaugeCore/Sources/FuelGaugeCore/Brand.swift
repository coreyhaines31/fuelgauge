import Foundation

public enum Brand {
    public static let name = "Fuel Gauge"
    public static let bundleIdentifier = "app.fuelgauge.FuelGauge"
    public static let site = "https://fuelgauge.app"

    /// Where the app and the command keep their readings: ~/Library/Application Support/Fuel Gauge.
    public static var supportFolder: URL {
        if let override = ProcessInfo.processInfo.environment["FUELGAUGE_HOME"] {
            return URL(filePath: override)
        }
        return URL.applicationSupportDirectory.appending(path: name)
    }
}
