// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxContinuityCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxContinuityCore", targets: ["NoxContinuityCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxContextCore"),
        .package(path: "../NoxMemoryCore"),
        .package(path: "../NoxSemanticCore"),
    ],
    targets: [
        .target(
            name: "NoxContinuityCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxContextCore", package: "NoxContextCore"),
                .product(name: "NoxMemoryCore", package: "NoxMemoryCore"),
                .product(name: "NoxSemanticCore", package: "NoxSemanticCore"),
            ]
        ),
        .testTarget(
            name: "NoxContinuityCoreTests",
            dependencies: ["NoxContinuityCore"]
        ),
    ]
)
