// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxCore", targets: ["NoxCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NoxCore",
            dependencies: []
        ),
        .testTarget(
            name: "NoxCoreTests",
            dependencies: ["NoxCore"]
        ),
    ]
)
