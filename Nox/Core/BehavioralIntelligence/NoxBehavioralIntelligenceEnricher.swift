import Foundation

nonisolated enum NoxBehavioralIntelligenceEnricher {

    static func enrichmentNotes(snapshot: NoxBehavioralIntelligenceSnapshot) -> [String] {
        var notes: [String] = snapshot.enrichmentNotes
        if let drift = snapshot.drift {
            notes.append("\(drift.label) — \(drift.detail)")
        }
        for structure in snapshot.lifeStructures.prefix(2) {
            notes.append(structure.detail)
        }
        return notes
            .map { NoxEmotionalSafetyCopy.sanitize($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .prefix(4)
            .map { $0 }
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
