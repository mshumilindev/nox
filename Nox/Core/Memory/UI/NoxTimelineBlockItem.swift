import Foundation

enum NoxTimelineBlockKind: Equatable, Sendable {
    case activitySpan(NoxActivitySpan)
    case focusBlock(NoxFocusBlock)
    case interruption(NoxInterruption)
    case fragmentedSummary(switchCount: Int, durationMs: Int)
    case semanticSpan(NoxSemanticMemorySpan)
    case continuityThread(NoxContinuityThread)
}

struct NoxTimelineBlockItem: Identifiable, Equatable, Sendable {
    let id: String
    let timestamp: Date
    let kind: NoxTimelineBlockKind
    let title: String
    let subtitle: String?
    let detailLine: String?
    let durationText: String?
    let category: NoxActivityCategory?
    let markerSymbol: String?
}
