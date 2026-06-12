// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FootballCore",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "FootballCore", targets: ["FootballCore"])
    ],
    targets: [
        .target(name: "FootballCore")
    ]
)
