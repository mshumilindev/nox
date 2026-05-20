import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

/// Rules for long-term memory of sensitive/private activity — trust over precision.
public enum NoxSensitiveMemoryPolicy {

    public static func memoryTitle(
        sensitivity: NoxSensitivityLevel,
        fallback: String = "Activity"
    ) -> String {
        NoxSensitiveContextHandler.genericMemoryTitle(sensitivity: sensitivity)
    }

    public static func memorySubtitle(sensitivity: NoxSensitivityLevel) -> String {
        switch sensitivity {
        case .privateContext:
            "Generalized private activity"
        case .sensitive:
            "Sensitive browsing — minimal detail retained"
        case .personal:
            "Personal activity — coarse summary only"
        case .normal:
            ""
        }
    }

    public static func allowsDetailedSemanticLabel(_ sensitivity: NoxSensitivityLevel) -> Bool {
        sensitivity == .normal
    }

    public static func allowsDomainInMemory(_ sensitivity: NoxSensitivityLevel) -> Bool {
        sensitivity == .normal
    }

    public static func allowsWindowTitleInMemory(_ sensitivity: NoxSensitivityLevel) -> Bool {
        sensitivity == .normal
    }

    public static func sanitizedForLongTermStorage(
        title: String?,
        subtitle: String?,
        sensitivity: NoxSensitivityLevel
    ) -> (title: String, subtitle: String) {
        guard !allowsDetailedSemanticLabel(sensitivity) else {
            return (title: title ?? memoryTitle(sensitivity: sensitivity), subtitle: subtitle ?? "")
        }
        return (
            title: memoryTitle(sensitivity: sensitivity),
            subtitle: memorySubtitle(sensitivity: sensitivity)
        )
    }
}
