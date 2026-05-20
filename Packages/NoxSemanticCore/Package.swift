// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxSemanticCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxSemanticCore", targets: ["NoxSemanticCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxContextCore"),
    ],
    targets: [
        .target(
            name: "NoxSemanticCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxContextCore", package: "NoxContextCore"),
            ]
        ),
        .testTarget(
            name: "NoxSemanticCoreTests",
            dependencies: ["NoxSemanticCore"]
        ),
    ]
)
