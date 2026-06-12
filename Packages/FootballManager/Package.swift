// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FootballManager",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "FootballManager", targets: ["FootballManager"])
    ],
    dependencies: [
        .package(path: "../FootballCore"),
        .package(path: "../FootballAPI"),
        .package(path: "../FootballStorage")
    ],
    targets: [
        .target(
            name: "FootballManager",
            dependencies: [
                .product(name: "FootballCore", package: "FootballCore"),
                .product(name: "FootballAPI", package: "FootballAPI"),
                .product(name: "FootballStorage", package: "FootballStorage")
            ]
        )
    ]
)
