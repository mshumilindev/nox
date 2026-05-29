// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxShrineCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxShrineCore", targets: ["NoxShrineCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NoxShrineCore",
            dependencies: []
        ),
        .testTarget(
            name: "NoxShrineCoreTests",
            dependencies: ["NoxShrineCore"]
        ),
    ]
)
