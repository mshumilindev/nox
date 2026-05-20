// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxObservatoryCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxObservatoryCore", targets: ["NoxObservatoryCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxMemoryCore"),
        .package(path: "../NoxSemanticCore"),
        .package(path: "../NoxContinuityCore"),
        .package(path: "../NoxContextCore"),
    ],
    targets: [
        .target(
            name: "NoxObservatoryCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxMemoryCore", package: "NoxMemoryCore"),
                .product(name: "NoxSemanticCore", package: "NoxSemanticCore"),
                .product(name: "NoxContinuityCore", package: "NoxContinuityCore"),
                .product(name: "NoxContextCore", package: "NoxContextCore"),
            ]
        ),
        .testTarget(
            name: "NoxObservatoryCoreTests",
            dependencies: ["NoxObservatoryCore"]
        ),
    ]
)
