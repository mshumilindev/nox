import Foundation

nonisolated enum NoxUnfinishedThreadEngine {

    static func candidates(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        at date: Date = Date()
    ) -> [NoxUnfinishedContinuityCandidate] {
        var results: [NoxUnfinishedContinuityCandidate] = []

        for thread in threads where thread.totalResumptions >= 1 {
            let score = NoxContinuityPersistenceModel.persistenceScore(thread: thread, arcs: arcs, at: date)
            guard score >= 0.48 else { continue }
            let name = thread.title.replacingOccurrences(of: " continuity", with: "")
            let detail: String
            if thread.totalResumptions >= 3 {
                detail = "\(name) keeps returning across sessions without fully settling."
            } else {
                detail = "\(name) has resurfaced after interruption more than once."
            }
            results.append(NoxUnfinishedContinuityCandidate(
                id: "unfinished-\(thread.id)",
                label: name,
                detail: NoxEmotionalSafetyCopy.sanitize(detail),
                persistenceScore: score,
                resumptions: thread.totalResumptions
            ))
        }

        for arc in arcs where arc.continuityState == .resurfaced && arc.strength >= 0.45 {
            results.append(NoxUnfinishedContinuityCandidate(
                id: "unfinished-arc-\(arc.id)",
                label: arc.label,
                detail: "This thread of work has resurfaced repeatedly lately.",
                persistenceScore: arc.strength,
                resumptions: arc.sessionTouches
            ))
        }

        return results
            .sorted { $0.persistenceScore > $1.persistenceScore }
            .prefix(4)
            .map { $0 }
    }
}
