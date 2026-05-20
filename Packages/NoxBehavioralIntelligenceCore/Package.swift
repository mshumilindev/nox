// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxBehavioralIntelligenceCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxBehavioralIntelligenceCore", targets: ["NoxBehavioralIntelligenceCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxContextCore"),
        .package(path: "../NoxMemoryCore"),
        .package(path: "../NoxContinuityCore"),
    ],
    targets: [
        .target(
            name: "NoxBehavioralIntelligenceCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxContextCore", package: "NoxContextCore"),
                .product(name: "NoxMemoryCore", package: "NoxMemoryCore"),
                .product(name: "NoxContinuityCore", package: "NoxContinuityCore"),
            ]
        ),
        .testTarget(
            name: "NoxBehavioralIntelligenceCoreTests",
            dependencies: ["NoxBehavioralIntelligenceCore"]
        ),
    ]
)
