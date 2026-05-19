import Foundation

struct NoxAmbientPreferences: Codable, Equatable, Sendable {
    var windowMode: NoxWindowMode
    var navigationDestination: NoxSemanticDestination
    var surfaceDensity: NoxSurfaceDensity
    var pauseState: NoxAmbientPauseState
    var hasSeenTrustOnboarding: Bool

    static let `default` = NoxAmbientPreferences(
        windowMode: .expanded,
        navigationDestination: .now,
        surfaceDensity: .calm,
        pauseState: .active,
        hasSeenTrustOnboarding: false
    )
}
