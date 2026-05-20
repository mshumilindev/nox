// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxSystemStateCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxSystemStateCore", targets: ["NoxSystemStateCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxAmbientUtilityCore"),
    ],
    targets: [
        .target(
            name: "NoxSystemStateCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxAmbientUtilityCore", package: "NoxAmbientUtilityCore"),
            ]
        ),
        .testTarget(
            name: "NoxSystemStateCoreTests",
            dependencies: ["NoxSystemStateCore"]
        ),
    ]
)
