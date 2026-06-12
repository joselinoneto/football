// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FootballAPI",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "FootballAPI", targets: ["FootballAPI"])
    ],
    dependencies: [
        .package(path: "../FootballCore")
    ],
    targets: [
        .target(
            name: "FootballAPI",
            dependencies: [
                .product(name: "FootballCore", package: "FootballCore")
            ]
        ),
        .testTarget(
            name: "FootballAPITests",
            dependencies: ["FootballAPI"]
        )
    ]
)
