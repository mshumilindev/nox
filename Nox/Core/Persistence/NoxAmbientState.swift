import Foundation

struct NoxAmbientState: Codable, Equatable, Sendable {
    var lastPresence: String?
    var lastActiveAppName: String?
    var lastActiveBundleId: String?
    var lastActiveWindowTitle: String?
    var observationStartedAt: Date?
    var lastShutdownAt: Date?
    var recentBundleIds: [String]
    var continuityNote: String?
    var lastMorningSummaryAt: Date?
    var lastResurfacingShownAt: Date?

    static let empty = NoxAmbientState(
        lastPresence: nil,
        lastActiveAppName: nil,
        lastActiveBundleId: nil,
        lastActiveWindowTitle: nil,
        observationStartedAt: nil,
        lastShutdownAt: nil,
        recentBundleIds: [],
        continuityNote: nil,
        lastMorningSummaryAt: nil,
        lastResurfacingShownAt: nil
    )
}

struct NoxPersistedSignalTracker: Codable, Equatable, Sendable {
    var firstSignalAt: Date?
    var currentBundleId: String?
    var currentAppStartedAt: Date?
    var switchTimestamps: [Date]
}
