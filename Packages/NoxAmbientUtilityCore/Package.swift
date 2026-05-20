// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxAmbientUtilityCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxAmbientUtilityCore", targets: ["NoxAmbientUtilityCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxContinuityCore"),
        .package(path: "../NoxBehavioralIntelligenceCore"),
        .package(path: "../NoxMemoryCore"),
    ],
    targets: [
        .target(
            name: "NoxAmbientUtilityCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxContinuityCore", package: "NoxContinuityCore"),
                .product(name: "NoxBehavioralIntelligenceCore", package: "NoxBehavioralIntelligenceCore"),
                .product(name: "NoxMemoryCore", package: "NoxMemoryCore"),
            ]
        ),
        .testTarget(
            name: "NoxAmbientUtilityCoreTests",
            dependencies: ["NoxAmbientUtilityCore"]
        ),
    ]
)
