// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxMemoryCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxMemoryCore", targets: ["NoxMemoryCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxContextCore"),
        .package(path: "../NoxSemanticCore"),
    ],
    targets: [
        .target(
            name: "NoxMemoryCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxContextCore", package: "NoxContextCore"),
                .product(name: "NoxSemanticCore", package: "NoxSemanticCore"),
            ]
        ),
        .testTarget(
            name: "NoxMemoryCoreTests",
            dependencies: [
                "NoxMemoryCore",
                .product(name: "NoxSemanticCore", package: "NoxSemanticCore"),
            ]
        ),
    ]
)
