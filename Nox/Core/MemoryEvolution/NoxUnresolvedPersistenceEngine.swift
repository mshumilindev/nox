import Foundation

nonisolated enum NoxUnresolvedPersistenceEngine {

    static func signals(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        storedReturns: inout [String: Int],
        at date: Date = Date()
    ) -> [NoxUnresolvedContinuitySignal] {
        var results: [NoxUnresolvedContinuitySignal] = []

        for thread in threads where thread.sensitivityLevel == .normal {
            let months = NoxTemporalDistanceModel.monthsSinceFirstSeen(thread.firstSeenAt, at: date)
            guard months >= 1 else { continue }

            let longGap = date.timeIntervalSince(thread.lastSeenAt) > 14 * 86_400
            let unresolved = (thread.decayState == .dormant || thread.decayState == .fading)
                && (thread.totalResumptions >= 1 || thread.recurrenceStrength >= 0.35)

            if unresolved && longGap {
                let count = max(storedReturns[thread.id] ?? 0, thread.totalResumptions)
                if count > (storedReturns[thread.id] ?? 0) {
                    storedReturns[thread.id] = count
                }
                let score = min(1, months * 0.15 + Double(count) * 0.08 + thread.recurrenceStrength * 0.25)
                let name = thread.title.replacingOccurrences(of: " continuity", with: "").lowercased()
                results.append(NoxUnresolvedContinuitySignal(
                    subjectId: thread.id,
                    persistenceScore: score,
                    detail: "\(name) has stayed open across longer gaps without fully settling."
                ))
            }
        }

        for arc in arcs where arc.continuityState == .resurfaced || arc.evolution == .stable {
            guard arc.strength >= 0.42 else { continue }
            var count = storedReturns[arc.id] ?? 0
            if arc.continuityState == .resurfaced, count == 0 {
                count = 1
                storedReturns[arc.id] = count
            }
            if count >= 1 || arc.continuityState == .resurfaced {
                results.append(NoxUnresolvedContinuitySignal(
                    subjectId: arc.id,
                    persistenceScore: min(1, arc.strength + Double(count) * 0.06),
                    detail: "\(arc.label) keeps resurfacing without a clean close."
                ))
            }
        }

        return results
            .sorted { $0.persistenceScore > $1.persistenceScore }
            .prefix(3)
            .map { $0 }
    }
}
