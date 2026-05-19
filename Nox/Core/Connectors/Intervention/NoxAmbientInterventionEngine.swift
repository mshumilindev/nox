import Foundation

enum NoxAmbientInterventionEngine {

    private static let cooldown: TimeInterval = 6 * 3600

    static func evaluate(
        transitions: [NoxTransitionEvent],
        cadencePatterns: [NoxCadencePattern],
        overloadSignals: [NoxOverloadSignal],
        calendarSignals: [NoxGeneralizedSignal],
        lastInterventionAt: Date?,
        at date: Date = Date()
    ) -> NoxAmbientIntervention? {
        if let last = lastInterventionAt, date.timeIntervalSince(last) < cooldown {
            return nil
        }

        if transitions.contains(where: { $0.kind == .returningAfterAbsence && $0.confidence >= 0.7 }) {
            return intervention(
                id: "intervention-return",
                kind: .resurfacingAfterReturn,
                label: "Continuity may feel familiar again.",
                detail: "A calm resurfacing — nothing to act on.",
                at: date
            )
        }

        if overloadSignals.contains(where: { $0.id == "overload-fragmentation" }) {
            return intervention(
                id: "intervention-fragmented",
                kind: .fragmentedDayAck,
                label: "The day has felt scattered.",
                detail: "Noticed on this Mac — not a warning.",
                at: date
            )
        }

        if cadencePatterns.contains(where: { $0.id == "rhythm-recovery" })
            && overloadSignals.count >= 2 {
            return intervention(
                id: "intervention-recovery",
                kind: .recoveryAwareShift,
                label: "Rhythm may be shifting toward recovery.",
                detail: "Nox stays quiet unless this pattern repeats.",
                at: date
            )
        }

        if calendarSignals.contains(where: { $0.id == "calendar-late-evening" })
            || cadencePatterns.contains(where: { $0.id == "rhythm-deep-focus-era" }) {
            let hour = Calendar.current.component(.hour, from: date)
            if hour >= 22 {
                return intervention(
                    id: "intervention-late-night",
                    kind: .lateNightCadence,
                    label: "Late-night cadence has appeared again.",
                    detail: "A gentle recognition — not coaching.",
                    at: date
                )
            }
        }

        return nil
    }

    private static func intervention(
        id: String,
        kind: NoxInterventionKind,
        label: String,
        detail: String,
        at date: Date
    ) -> NoxAmbientIntervention {
        NoxAmbientIntervention(
            id: id,
            label: label,
            detail: detail,
            kind: kind,
            observedAt: date
        )
    }
}
