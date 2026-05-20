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

/// Timeline rail icons — always validated SF Symbols with calm, meaningful defaults.
nonisolated enum NoxTimelineSymbol {
    static func name(for block: NoxTimelineBlockItem) -> String {
        if let marker = block.markerSymbol {
            return NoxSFSymbol.validated(marker, fallback: fallback(for: block))
        }
        return fallback(for: block)
    }

    private static func fallback(for block: NoxTimelineBlockItem) -> String {
        switch block.kind {
        case .continuityThread:
            return NoxSFSymbol.validated("link", fallback: "circle.fill")
        case .semanticSpan:
            return NoxSFSymbol.validated("sparkles", fallback: "circle.fill")
        case .focusBlock(let focus):
            switch focus.kind {
            case .fragmented:
                return NoxSFSymbol.validated("arrow.triangle.branch", fallback: "circle.fill")
            case .deepWork, .focused:
                return NoxSFSymbol.validated("scope", fallback: "circle.fill")
            }
        case .interruption:
            return NoxSFSymbol.validated("arrow.left.arrow.right", fallback: "circle.fill")
        case .activitySpan(let span):
            return span.category.symbolName
        case .fragmentedSummary:
            return NoxSFSymbol.validated("arrow.triangle.branch", fallback: "circle.fill")
        case .resurfacingMemory:
            return NoxSFSymbol.validated("arrow.uturn.backward", fallback: "link")
        }
    }
}
