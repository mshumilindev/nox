import Foundation

nonisolated struct NoxAmbientPreferences: Codable, Equatable, Sendable {
    var windowMode: NoxWindowMode
    var navigationDestination: NoxSemanticDestination
    var surfaceDensity: NoxSurfaceDensity
    var pauseState: NoxAmbientPauseState
    var hasSeenTrustOnboarding: Bool
    var connectors: NoxConnectorPreferences

    init(
        windowMode: NoxWindowMode,
        navigationDestination: NoxSemanticDestination,
        surfaceDensity: NoxSurfaceDensity,
        pauseState: NoxAmbientPauseState,
        hasSeenTrustOnboarding: Bool,
        connectors: NoxConnectorPreferences = .default
    ) {
        self.windowMode = windowMode
        self.navigationDestination = navigationDestination
        self.surfaceDensity = surfaceDensity
        self.pauseState = pauseState
        self.hasSeenTrustOnboarding = hasSeenTrustOnboarding
        self.connectors = connectors
    }

    static let `default` = NoxAmbientPreferences(
        windowMode: .expanded,
        navigationDestination: .now,
        surfaceDensity: .calm,
        pauseState: .active,
        hasSeenTrustOnboarding: false,
        connectors: .default
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        windowMode = try container.decode(NoxWindowMode.self, forKey: .windowMode)
        navigationDestination = try container.decode(NoxSemanticDestination.self, forKey: .navigationDestination)
        surfaceDensity = try container.decode(NoxSurfaceDensity.self, forKey: .surfaceDensity)
        pauseState = try container.decode(NoxAmbientPauseState.self, forKey: .pauseState)
        hasSeenTrustOnboarding = try container.decode(Bool.self, forKey: .hasSeenTrustOnboarding)
        connectors = try container.decodeIfPresent(NoxConnectorPreferences.self, forKey: .connectors) ?? .default
    }
}
