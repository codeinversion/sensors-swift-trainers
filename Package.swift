// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "SwiftySensorsTrainers",
    platforms: [.macOS(.v10_13), .iOS(.v9), .tvOS(.v10)],
    products: [
        .library(name: "SwiftySensorsTrainers", targets: ["SwiftySensorsTrainers"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kinetic-fit/sensors-swift", .branch("master")),
        .package(url: "https://github.com/kinetic-fit/sensors-swift-kinetic", .branch("master"))
    ],
    targets: [
        .target(name: "SwiftySensorsTrainers", dependencies: ["SwiftySensors", "KineticSensors"])
    ]
)
