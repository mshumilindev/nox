import Foundation

/// Presentation-only temporal emphasis for memory surfaces (not engine state).
nonisolated enum NoxMemoryTemporalState: String, Sendable {
    case active
    case fading
    case dormant
    case archival
    case resurfacing

    static func from(agingBand: NoxMemoryAgingBand) -> NoxMemoryTemporalState {
        switch agingBand {
        case .recentlyActive: return .active
        case .fading: return .fading
        case .dormant: return .dormant
        case .archival: return .archival
        case .resurfacing: return .resurfacing
        }
    }
}

nonisolated struct NoxTimelineRowPresentation: Equatable, Sendable {
    let temporalState: NoxMemoryTemporalState
    let titleOpacity: Double
    let metadataOpacity: Double
    let detailOpacity: Double
    let iconOpacity: Double
    let suppressDuration: Bool
    let relationLine: String?

    static let active = NoxTimelineRowPresentation(
        temporalState: .active,
        titleOpacity: 0.92,
        metadataOpacity: 0.58,
        detailOpacity: 0.48,
        iconOpacity: 1,
        suppressDuration: false,
        relationLine: nil
    )
}
