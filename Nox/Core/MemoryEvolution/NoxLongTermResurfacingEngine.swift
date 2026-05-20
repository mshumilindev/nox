import Foundation

nonisolated enum NoxLongTermResurfacingEngine {

    static let cooldownSeconds: TimeInterval = 7 * 24 * 3600

    static func notes(
        threads: [NoxContinuityThread],
        arcs: [NoxSemanticArc],
        agingProfiles: [NoxMemoryAgingProfile],
        unresolved: [NoxUnresolvedContinuitySignal],
        lastShownAt: Date?,
        preferSilence: Bool,
        at date: Date = Date()
    ) -> [String] {
        guard !preferSilence else { return [] }
        if let last = lastShownAt, date.timeIntervalSince(last) < cooldownSeconds {
            return []
        }

        let profileMap = Dictionary(uniqueKeysWithValues: agingProfiles.map { ($0.subjectId, $0) })
        var notes: [String] = []

        if let signal = unresolved.first(where: { $0.persistenceScore >= 0.55 }) {
            notes.append(signal.detail)
        }

        if notes.isEmpty {
            let dormantReturn = threads
                .filter { thread in
                    guard thread.sensitivityLevel == .normal else { return false }
                    let gap = date.timeIntervalSince(thread.lastSeenAt)
                    guard gap >= 72 * 3600, gap <= 45 * 86_400 else { return false }
                    let band = profileMap[thread.id]?.band
                    return band == .dormant || band == .resurfacing
                }
                .sorted { $0.recurrenceStrength > $1.recurrenceStrength }
                .first

            if let thread = dormantReturn, NoxContinuityDecay.canResurface(thread, at: date) {
                let name = thread.title.replacingOccurrences(of: " continuity", with: "").lowercased()
                notes.append("\(name) activity returned after a longer absence.")
            }
        }

        if notes.isEmpty,
           let arc = arcs.first(where: {
               $0.continuityState == .resurfaced
                   && $0.strength >= 0.5
                   && (profileMap[$0.id]?.temporalDistance ?? 1) >= 0.35
           }) {
            notes.append("\(arc.label) activity returned in recent long-term memory.")
        }

        return Array(notes.prefix(1))
    }
}
