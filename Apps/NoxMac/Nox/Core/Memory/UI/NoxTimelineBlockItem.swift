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

enum NoxTimelineBlockKind: Equatable, Sendable {
    case activitySpan(NoxActivitySpan)
    case focusBlock(NoxFocusBlock)
    case interruption(NoxInterruption)
    case fragmentedSummary(switchCount: Int, durationMs: Int)
    case semanticSpan(NoxSemanticMemorySpan)
    case continuityThread(NoxContinuityThread)
    case resurfacingMemory
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
    let presentation: NoxTimelineRowPresentation?
    let isLongTermResurfacing: Bool

    init(
        id: String,
        timestamp: Date,
        kind: NoxTimelineBlockKind,
        title: String,
        subtitle: String?,
        detailLine: String?,
        durationText: String?,
        category: NoxActivityCategory?,
        markerSymbol: String?,
        presentation: NoxTimelineRowPresentation? = nil,
        isLongTermResurfacing: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.detailLine = detailLine
        self.durationText = durationText
        self.category = category
        self.markerSymbol = markerSymbol
        self.presentation = presentation
        self.isLongTermResurfacing = isLongTermResurfacing
    }
}
