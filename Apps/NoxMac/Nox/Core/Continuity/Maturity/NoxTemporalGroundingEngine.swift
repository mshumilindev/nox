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

nonisolated enum NoxTemporalGroundingEngine {

    static func groundedHeadline(
        reflectionId: String,
        rawHeadline: String,
        input: NoxReflectionInput
    ) -> String {
        let prefix = temporalPrefix(reflectionId: reflectionId, input: input)
        let body = NoxReflectiveLanguageSoftener.soften(rawHeadline)
        guard let prefix, !body.lowercased().hasPrefix(prefix.lowercased()) else {
            return body
        }
        if body.first?.isLowercase == true {
            return "\(prefix), \(body)"
        }
        let lowered = body.prefix(1).lowercased() + body.dropFirst()
        return "\(prefix), \(lowered)"
    }

    static func groundedDetail(reflectionId: String, rawDetail: String) -> String {
        let softened = NoxReflectiveLanguageSoftener.softenDetail(rawDetail)
        if softened.isEmpty {
            return "Drawn from local memory over recent days — not advice."
        }
        return softened
    }

    private static func temporalPrefix(reflectionId: String, input: NoxReflectionInput) -> String? {
        switch reflectionId {
        case "reflection-resurfaced-arc":
            if input.continuityResumptions >= 3 { return "Repeatedly this week" }
            return "After interruption"
        case "reflection-recurring-thread":
            return input.hasPriorDayActivity ? "Over several days" : "Recently"
        case "reflection-behavioral-pattern":
            return "Lately"
        case "reflection-behavioral-drift":
            return "Over the last several days"
        case "reflection-life-structure":
            return "Gradually"
        case "reflection-context-switching":
            return "Intermittently"
        case "reflection-creative-arc":
            return "This week"
        case "reflection-fragmentation":
            return "Recently"
        case "reflection-weekly-horizon":
            return "Across the week"
        case "reflection-focus-rhythm":
            return input.periodLabel == "Today" ? "Today" : "Recently"
        default:
            return nil
        }
    }
}
