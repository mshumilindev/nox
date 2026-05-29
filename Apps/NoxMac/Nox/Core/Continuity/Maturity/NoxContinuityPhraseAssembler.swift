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

nonisolated enum NoxContinuityPhraseAssembler {

    static func resurfacedArcPhrase(
        arcName: String?,
        resumptions: Int,
        salience: NoxContinuitySalience
    ) -> String {
        let name = arcName.map { softenArcName($0) }
        switch salience {
        case .unresolved, .returning:
            if let name {
                return "\(name) keeps returning after breaks — \(resumptionClause(resumptions))."
            }
            return "Interrupted work keeps returning — \(resumptionClause(resumptions))."
        case .heavy:
            if let name {
                return "\(name) has carried weight again after stopping — \(resumptionClause(resumptions))."
            }
            return "A heavier through-line returned after stopping — \(resumptionClause(resumptions))."
        default:
            if let name {
                return "\(name) picked up again after interruption — \(resumptionClause(resumptions))."
            }
            return "Interrupted continuity picked up again — \(resumptionClause(resumptions))."
        }
    }

    static func fragmentationPhrase(fragmentedSessions: Int, salience: NoxContinuitySalience) -> String {
        switch salience {
        case .fragile:
            return "Attention has been thin — context keeps breaking apart."
        case .quiet:
            return "The day stayed light and scattered."
        default:
            if fragmentedSessions >= 3 {
                return "Recent continuity has repeatedly shifted between focus and abrupt fragmentation."
            }
            return "Attention has been splitting often between contexts."
        }
    }

    static func behavioralContinuityPhrase(
        patternDetail: String,
        salience: NoxContinuitySalience
    ) -> String {
        let core = NoxReflectiveLanguageSoftener.soften(patternDetail)
        switch salience {
        case .stable:
            return core.hasSuffix(".") ? core : "\(core)."
        case .fragile:
            return "Rhythm still feels unsettled — \(core.lowercased())"
        default:
            return core.hasSuffix(".") ? core : "\(core)."
        }
    }

    static func contextSwitchPhrase(development: String, research: String) -> String {
        "Work has been moving between \(development.lowercased()) and \(research.lowercased()) without settling on one lane."
    }

    private static func resumptionClause(_ count: Int) -> String {
        count >= 3 ? "several returns across recent sessions" : "a few returns across recent sessions"
    }

    private static func softenArcName(_ name: String) -> String {
        name
            .replacingOccurrences(of: " continuity", with: "")
            .replacingOccurrences(of: " context", with: "")
    }
}
