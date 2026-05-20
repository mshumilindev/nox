// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoxPresenceCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "NoxPresenceCore", targets: ["NoxPresenceCore"]),
    ],
    dependencies: [
        .package(path: "../NoxCore"),
        .package(path: "../NoxMemoryCore"),
    ],
    targets: [
        .target(
            name: "NoxPresenceCore",
            dependencies: [
                .product(name: "NoxCore", package: "NoxCore"),
                .product(name: "NoxMemoryCore", package: "NoxMemoryCore"),
            ]
        ),
        .testTarget(
            name: "NoxPresenceCoreTests",
            dependencies: [
                "NoxPresenceCore",
                .product(name: "NoxCore", package: "NoxCore"),
            ]
        ),
    ]
)
