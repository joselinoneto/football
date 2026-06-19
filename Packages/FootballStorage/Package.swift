// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FootballStorage",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1), .watchOS(.v10)],
    products: [
        .library(name: "FootballStorage", targets: ["FootballStorage"])
    ],
    dependencies: [
        .package(path: "../FootballCore")
    ],
    targets: [
        .target(
            name: "FootballStorage",
            dependencies: [
                .product(name: "FootballCore", package: "FootballCore")
            ]
        ),
        .testTarget(
            name: "FootballStorageTests",
            dependencies: ["FootballStorage"]
        )
    ]
)
