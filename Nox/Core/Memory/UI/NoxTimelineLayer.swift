import Foundation

nonisolated enum NoxTimelineLayer: String, CaseIterable, Sendable {
    case continuity
    case semantic
    case focus
    case activity
    case interruption

    var title: String {
        switch self {
        case .continuity: "Continuity"
        case .semantic: "Semantic memory"
        case .focus: "Focus"
        case .activity: "Activity"
        case .interruption: "Interruptions"
        }
    }

    static let displayOrder: [NoxTimelineLayer] = [
        .continuity,
        .semantic,
        .focus,
        .activity,
        .interruption
    ]
}

struct NoxTimelineSection: Identifiable, Equatable, Sendable {
    let layer: NoxTimelineLayer
    let items: [NoxTimelineBlockItem]

    var id: String { layer.rawValue }
}
