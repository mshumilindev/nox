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

nonisolated enum NoxMemoryRelationPresenter {

  static func relationLine(
    subjectId: String,
    semanticType: NoxContinuitySemanticType?,
    threads: [NoxContinuityThread],
    arcs: [NoxSemanticArc],
    ecologyCoupling: [String: Double],
    ecologyNotes: [String],
    at: Date = Date()
  ) -> String? {
    let coupling = ecologyCoupling[subjectId] ?? 0
    guard coupling >= 0.4 else { return nil }

    if let partner = strongestPartner(
      subjectId: subjectId,
      semanticType: semanticType,
      threads: threads,
      at: at
    ) {
      let name = partner.title
        .replacingOccurrences(of: " continuity", with: "")
        .lowercased()
      return "connected to recent \(name) activity"
    }

    if ecologyNotes.contains(where: { $0.localizedCaseInsensitiveContains("strengthening") }),
       semanticType == .development || semanticType == .aiDevelopment {
      return "returned alongside repeated development activity"
    }

    if let arc = arcs.first(where: { ($0.strength) >= 0.55 && $0.id != subjectId }) {
      return "returned alongside repeated \(arc.label.lowercased()) activity"
    }

    return nil
  }

  private static func strongestPartner(
    subjectId: String,
    semanticType: NoxContinuitySemanticType?,
    threads: [NoxContinuityThread],
    at: Date
  ) -> NoxContinuityThread? {
    threads
      .filter { thread in
        guard thread.id != subjectId, thread.sensitivityLevel == .normal else { return false }
        guard at.timeIntervalSince(thread.lastSeenAt) < 5 * 86_400 else { return false }
        if let semanticType, thread.semanticType == semanticType { return false }
        return thread.continuityStrength >= 0.48 || thread.recurrenceStrength >= 0.4
      }
      .max { lhs, rhs in
        lhs.continuityStrength * lhs.recurrenceStrength < rhs.continuityStrength * rhs.recurrenceStrength
      }
  }
}
