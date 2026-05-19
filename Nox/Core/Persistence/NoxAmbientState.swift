import Foundation

nonisolated struct NoxAmbientState: Codable, Equatable, Sendable {
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
    var lastConnectorInterventionAt: Date?
    var lastConnectorFocusKind: String?
    var recentConnectorDensities: [Double]

    init(
        lastPresence: String?,
        lastActiveAppName: String?,
        lastActiveBundleId: String?,
        lastActiveWindowTitle: String?,
        observationStartedAt: Date?,
        lastShutdownAt: Date?,
        recentBundleIds: [String],
        continuityNote: String?,
        lastMorningSummaryAt: Date?,
        lastResurfacingShownAt: Date?,
        lastConnectorInterventionAt: Date? = nil,
        lastConnectorFocusKind: String? = nil,
        recentConnectorDensities: [Double] = []
    ) {
        self.lastPresence = lastPresence
        self.lastActiveAppName = lastActiveAppName
        self.lastActiveBundleId = lastActiveBundleId
        self.lastActiveWindowTitle = lastActiveWindowTitle
        self.observationStartedAt = observationStartedAt
        self.lastShutdownAt = lastShutdownAt
        self.recentBundleIds = recentBundleIds
        self.continuityNote = continuityNote
        self.lastMorningSummaryAt = lastMorningSummaryAt
        self.lastResurfacingShownAt = lastResurfacingShownAt
        self.lastConnectorInterventionAt = lastConnectorInterventionAt
        self.lastConnectorFocusKind = lastConnectorFocusKind
        self.recentConnectorDensities = recentConnectorDensities
    }

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
        lastResurfacingShownAt: nil,
        lastConnectorInterventionAt: nil,
        lastConnectorFocusKind: nil,
        recentConnectorDensities: []
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastPresence = try container.decodeIfPresent(String.self, forKey: .lastPresence)
        lastActiveAppName = try container.decodeIfPresent(String.self, forKey: .lastActiveAppName)
        lastActiveBundleId = try container.decodeIfPresent(String.self, forKey: .lastActiveBundleId)
        lastActiveWindowTitle = try container.decodeIfPresent(String.self, forKey: .lastActiveWindowTitle)
        observationStartedAt = try container.decodeIfPresent(Date.self, forKey: .observationStartedAt)
        lastShutdownAt = try container.decodeIfPresent(Date.self, forKey: .lastShutdownAt)
        recentBundleIds = try container.decodeIfPresent([String].self, forKey: .recentBundleIds) ?? []
        continuityNote = try container.decodeIfPresent(String.self, forKey: .continuityNote)
        lastMorningSummaryAt = try container.decodeIfPresent(Date.self, forKey: .lastMorningSummaryAt)
        lastResurfacingShownAt = try container.decodeIfPresent(Date.self, forKey: .lastResurfacingShownAt)
        lastConnectorInterventionAt = try container.decodeIfPresent(Date.self, forKey: .lastConnectorInterventionAt)
        lastConnectorFocusKind = try container.decodeIfPresent(String.self, forKey: .lastConnectorFocusKind)
        recentConnectorDensities = try container.decodeIfPresent([Double].self, forKey: .recentConnectorDensities) ?? []
    }
}

nonisolated struct NoxPersistedSignalTracker: Codable, Equatable, Sendable {
    var firstSignalAt: Date?
    var currentBundleId: String?
    var currentAppStartedAt: Date?
    var switchTimestamps: [Date]
}
