// Shared platform matrix for Nox Swift packages (copy into Package.swift).
// macOS 14+, iOS 17+ (iPadOS), watchOS 10+, tvOS 17+, visionOS 1+

import PackageDescription

let noxSharedPlatforms: [SupportedPlatform] = [
    .macOS(.v14),
    .iOS(.v17),
    .watchOS(.v10),
    .tvOS(.v17),
    .visionOS(.v1),
]
