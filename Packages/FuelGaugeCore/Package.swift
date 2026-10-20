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
        .testTarget(name: "FuelGaugeCoreTests", dependencies: ["FuelGaugeCore"], resources: [.copy("Samples")])
    ]
)
