// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxContextCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxContextCore", targets: ["NoxContextCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
    ],
    targets: [
        .target(
            name: "NoxContextCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
            ]
        ),
        .testTarget(
            name: "NoxContextCoreTests",
            dependencies: [
                "NoxContextCore",
                .product(name: "NoxCore", package: "NoxCore"),
            ]
        ),
    ]
)
