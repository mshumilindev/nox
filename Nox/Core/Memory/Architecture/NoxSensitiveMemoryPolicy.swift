import Foundation

/// Rules for long-term memory of sensitive/private activity — trust over precision.
enum NoxSensitiveMemoryPolicy {

    static func memoryTitle(
        sensitivity: NoxSensitivityLevel,
        fallback: String = "Activity"
    ) -> String {
        NoxSensitiveContextHandler.genericMemoryTitle(sensitivity: sensitivity)
    }

    static func memorySubtitle(sensitivity: NoxSensitivityLevel) -> String {
        switch sensitivity {
        case .privateContext:
            "Generalized private continuity"
        case .sensitive:
            "Sensitive browsing — minimal detail retained"
        case .personal:
            "Personal activity — coarse summary only"
        case .normal:
            ""
        }
    }

    static func allowsDetailedSemanticLabel(_ sensitivity: NoxSensitivityLevel) -> Bool {
        sensitivity == .normal
    }

    static func allowsDomainInMemory(_ sensitivity: NoxSensitivityLevel) -> Bool {
        sensitivity == .normal
    }

    static func allowsWindowTitleInMemory(_ sensitivity: NoxSensitivityLevel) -> Bool {
        sensitivity == .normal
    }

    static func sanitizedForLongTermStorage(
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
