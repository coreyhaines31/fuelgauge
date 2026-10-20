// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FuelGaugeCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FuelGaugeCore", targets: ["FuelGaugeCore"])
    ],
    targets: [
        .target(name: "FuelGaugeCore"),
        // `swift run fuelgauge-dev` prints what the readers find on this Mac.
        .executableTarget(name: "fuelgauge-dev", dependencies: ["FuelGaugeCore"]),
        .testTarget(name: "FuelGaugeCoreTests", dependencies: ["FuelGaugeCore"], resources: [.copy("Samples")])
    ]
)
