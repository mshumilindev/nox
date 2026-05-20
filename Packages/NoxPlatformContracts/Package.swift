// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxPlatformContracts",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxPlatformContracts", targets: ["NoxPlatformContracts"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NoxPlatformContracts",
            dependencies: []
        ),
        .testTarget(
            name: "NoxPlatformContractsTests",
            dependencies: ["NoxPlatformContracts"]
        ),
    ]
)
