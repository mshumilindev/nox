import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore
import NoxShrineCore

nonisolated struct NoxAmbientPreferences: Codable, Equatable, Sendable {
    var windowMode: NoxWindowMode
    var navigationDestination: NoxSemanticDestination
    var surfaceDensity: NoxSurfaceDensity
    var pauseState: NoxAmbientPauseState
    var hasSeenTrustOnboarding: Bool
    var connectors: NoxConnectorPreferences
    var ambientUtility: NoxAmbientUtilityPreferences

    init(
        windowMode: NoxWindowMode,
        navigationDestination: NoxSemanticDestination,
        surfaceDensity: NoxSurfaceDensity,
        pauseState: NoxAmbientPauseState,
        hasSeenTrustOnboarding: Bool,
        connectors: NoxConnectorPreferences = .default,
        ambientUtility: NoxAmbientUtilityPreferences = .default
    ) {
        self.windowMode = windowMode
        self.navigationDestination = navigationDestination
        self.surfaceDensity = surfaceDensity
        self.pauseState = pauseState
        self.hasSeenTrustOnboarding = hasSeenTrustOnboarding
        self.connectors = connectors
        self.ambientUtility = ambientUtility
    }

    static let `default` = NoxAmbientPreferences(
        windowMode: .expanded,
        navigationDestination: .now,
        surfaceDensity: .calm,
        pauseState: .active,
        hasSeenTrustOnboarding: false,
        connectors: .default,
        ambientUtility: .default
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        windowMode = try container.decode(NoxWindowMode.self, forKey: .windowMode)
        navigationDestination = try container.decode(NoxSemanticDestination.self, forKey: .navigationDestination)
        surfaceDensity = try container.decode(NoxSurfaceDensity.self, forKey: .surfaceDensity)
        pauseState = try container.decode(NoxAmbientPauseState.self, forKey: .pauseState)
        hasSeenTrustOnboarding = try container.decode(Bool.self, forKey: .hasSeenTrustOnboarding)
        connectors = try container.decodeIfPresent(NoxConnectorPreferences.self, forKey: .connectors) ?? .default
        ambientUtility = try container.decodeIfPresent(NoxAmbientUtilityPreferences.self, forKey: .ambientUtility) ?? .default
    }
}
