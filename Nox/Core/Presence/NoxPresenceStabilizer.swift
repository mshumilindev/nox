import Foundation

/// Soft temporal inertia for presence transitions.
@MainActor
final class NoxPresenceStabilizer {
    private var stablePresence: NoxPresenceState = .quiet
    private var candidatePresence: NoxPresenceState?
    private var candidateSince: Date?

    var current: NoxPresenceState { stablePresence }

    func resolve(proposed: NoxPresenceState, at date: Date = Date()) -> NoxPresenceState {
        if proposed == stablePresence {
            candidatePresence = nil
            candidateSince = nil
            return stablePresence
        }

        if candidatePresence != proposed {
            candidatePresence = proposed
            candidateSince = date
        }

        let requiredHold = holdDuration(from: stablePresence, to: proposed)
        guard let since = candidateSince,
              date.timeIntervalSince(since) >= requiredHold else {
            return stablePresence
        }

        stablePresence = proposed
        candidatePresence = nil
        candidateSince = nil
        return stablePresence
    }

    func reset(to presence: NoxPresenceState) {
        stablePresence = presence
        candidatePresence = nil
        candidateSince = nil
    }

    private func holdDuration(from: NoxPresenceState, to: NoxPresenceState) -> TimeInterval {
        if to == .idle || to == .resting { return 60 }
        if from == .idle || from == .resting { return 10 }
        if from == .limited && to != .limited { return 12 }
        if to == .distracted { return 90 }
        if to == .focused || to == .flow { return 120 }
        if from == .focused || from == .flow {
            if to == .active || to == .distracted { return 50 }
            return 70
        }
        if from == .active && to == .quiet { return 35 }
        if from == .quiet && to == .active { return 25 }
        return 22
    }
}
