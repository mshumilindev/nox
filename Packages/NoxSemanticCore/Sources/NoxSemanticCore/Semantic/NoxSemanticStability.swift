import Foundation
import NoxCore
import NoxContextCore

/// Shared rules for when past switching should not dominate current reality.
public enum NoxSemanticStability {
    public static func isSustainedPassiveViewing(_ context: NoxSemanticContext, metrics: NoxInteractionMetrics) -> Bool {
        if let dominant = context.dominantContextType,
           context.dominantContextConfidence >= 0.45 {
            switch dominant {
            case .watching, .listening:
                return true
            default:
                break
            }
        }

        if NoxPassiveMediaContext.indicatesPassiveMedia(
            title: context.windowTitle,
            domain: context.domain,
            browserCategory: context.browserCategory
        ) {
            return true
        }

        if context.browserCategory == .entertainment, !metrics.isWritingHeavy {
            return true
        }

        return isSustainedPassiveBrowser(context, metrics: metrics)
    }

    public static func isSustainedPassiveBrowser(_ context: NoxSemanticContext, metrics: NoxInteractionMetrics) -> Bool {
        guard context.timeInCurrentApp >= 20,
              !metrics.isWritingHeavy else { return false }
        guard NoxAppFamilyResolver.resolve(
            bundleId: context.bundleId ?? "",
            appName: context.appName ?? "",
            category: .general
        ) == .browser else { return false }
        return metrics.isPassive
            || metrics.scrollIntensity < 1.5 && metrics.typingDensity < 0.8
    }

    public static func shouldSuppressFragmentedState(_ context: NoxSemanticContext, metrics: NoxInteractionMetrics) -> Bool {
        if isSustainedPassiveViewing(context, metrics: metrics) { return true }
        if context.timeInCurrentApp >= 45, context.fragmentationSwitchCount < 3 { return true }
        return false
    }
}
