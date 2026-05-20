import Foundation
import NoxSemanticCore
import NoxMemoryCore
import NoxContextCore
import NoxCore

/// Rare, calm resurfacing lines for long-horizon surfaces — not live-signal spam.
public enum NoxContinuityResurfacingOrchestrator {

    static let cooldownSeconds: TimeInterval = 900

    public static func resurfacingNotes(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        lastShownAt: Date?,
        at date: Date = Date()
    ) -> [String] {
        if let last = lastShownAt, date.timeIntervalSince(last) < cooldownSeconds {
            return []
        }

        var notes: [String] = []

        if let arcNote = arcResurfacingNote(arcs: arcs, at: date) {
            notes.append(arcNote)
        }
        if let threadNote = threadResurfacingNote(threads: threads, at: date) {
            notes.append(threadNote)
        }

        return Array(notes.prefix(2))
    }

    private static func arcResurfacingNote(arcs: [NoxSemanticArc], at date: Date) -> String? {
        guard let arc = arcs.first(where: { $0.continuityState == .resurfaced && $0.strength >= 0.45 }) else {
            return nil
        }
        return "\(arc.label) has been returning in bursts lately."
    }

    private static func threadResurfacingNote(threads: [NoxContinuityThread], at date: Date) -> String? {
        let candidate = threads
            .filter { $0.sensitivityLevel == .normal && $0.totalResumptions >= 1 }
            .sorted { $0.recurrenceStrength > $1.recurrenceStrength }
            .first

        guard let thread = candidate else { return nil }
        let gap = date.timeIntervalSince(thread.lastSeenAt)
        guard gap < 72 * 3600 else { return nil }

        let name = thread.title.replacingOccurrences(of: " continuity", with: "")
        if thread.totalResumptions >= 2 {
            return "There was a brief return to \(name.lowercased())."
        }
        return nil
    }
}
