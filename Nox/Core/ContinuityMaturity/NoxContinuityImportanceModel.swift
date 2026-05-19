import Foundation

nonisolated enum NoxContinuityImportanceModel {

    static func threadImportance(_ thread: NoxContinuityThread, at date: Date = Date()) -> Double {
        var score = thread.continuityStrength * 0.35
        score += thread.recurrenceStrength * 0.25
        score += min(0.2, Double(thread.totalResumptions) * 0.05)
        if thread.currentStatus == .resumed || thread.lastResumedAt != nil {
            score += 0.12
        }
        if thread.decayState == .fading {
            score -= 0.08
        }
        let days = max(0, date.timeIntervalSince(thread.firstSeenAt) / 86_400)
        if days >= 7 { score += 0.08 }
        if days >= 21 { score += 0.05 }
        return min(1, max(0, score))
    }

    static func arcImportance(_ arc: NoxSemanticArc) -> Double {
        var score = arc.strength * 0.4
        switch arc.continuityState {
        case .resurfaced: score += 0.22
        case .active: score += 0.1
        case .merging: score += 0.08
        case .fading, .dormant: score -= 0.1
        }
        switch arc.evolution {
        case .strengthening: score += 0.12
        case .fragmenting, .decaying: score -= 0.08
        case .stable: break
        }
        return min(1, max(0, score))
    }
}
