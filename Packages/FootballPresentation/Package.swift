// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FootballPresentation",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1), .watchOS(.v10)],
    products: [
        .library(name: "FootballPresentation", targets: ["FootballPresentation"])
    ],
    dependencies: [
        .package(path: "../FootballCore"),
        .package(path: "../FootballManager")
    ],
    targets: [
        .target(
            name: "FootballPresentation",
            dependencies: [
                .product(name: "FootballCore", package: "FootballCore"),
                .product(name: "FootballManager", package: "FootballManager")
            ],
            resources: [
                .process("Localizable.xcstrings")
            ]
        )
    ]
)
