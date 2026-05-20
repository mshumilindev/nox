// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxDesignCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxDesignCore", targets: ["NoxDesignCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
    ],
    targets: [
        .target(
            name: "NoxDesignCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
            ]
        ),
        .testTarget(
            name: "NoxDesignCoreTests",
            dependencies: ["NoxDesignCore"]
        ),
    ]
)
