import Foundation

nonisolated enum NoxObservatoryObservationEngine {
    static func observations(
        series: [NoxObservatorySignalSeries],
        maturity: NoxObservatoryMaturityLevel
    ) -> [NoxObservatoryObservation] {
        guard maturity >= .tentative else {
            return [
                NoxObservatoryObservation(
                    id: "maturity-\(maturity.rawValue)",
                    severity: .note,
                    title: "Still gathering",
                    detail: maturity.copy,
                    confidence: maturity.confidenceCeiling,
                    evidence: ["Not enough local activity yet for a strong read."]
                )
            ]
        }

        let lookup = Dictionary(uniqueKeysWithValues: series.map { ($0.signal, $0) })
        var observations: [NoxObservatoryObservation] = []

        if let recovery = lookup[.recovery], let coordination = lookup[.coordinationLoad],
           trend(recovery) < -0.12, average(coordination) > 0.52 {
            observations.append(observation(
                id: "recovery-shortening-coordination-rising",
                severity: .elevated,
                title: "Shorter breaks, more back-and-forth",
                detail: "Quiet stretches got shorter while scheduling and messages stayed busy.",
                confidence: min(recovery.confidence, coordination.confidence),
                evidence: ["Recovery trend \(formatTrend(trend(recovery))).", "Coordination average \(formatAverage(average(coordination)))."]
            ))
        }

        if let fragmentation = lookup[.fragmentation], let focus = lookup[.focusContinuity],
           average(fragmentation) > 0.58, average(focus) < 0.46 {
            observations.append(observation(
                id: "fragmentation-dominates-focus",
                severity: .elevated,
                title: "Lots of switching",
                detail: "You moved between many apps and tasks even when longer focus stretches would have been typical.",
                confidence: min(fragmentation.confidence, focus.confidence),
                evidence: ["Switching average \(formatAverage(average(fragmentation))).", "Focus average \(formatAverage(average(focus)))."]
            ))
        }

        if let deepWork = lookup[.deepWork], trend(deepWork) < -0.18, maturity >= .normal {
            observations.append(observation(
                id: "deep-work-collapse",
                severity: .severe,
                title: "Shorter focus stretches",
                detail: "Most work in this period happened in shorter blocks than earlier in the range.",
                confidence: deepWork.confidence,
                evidence: ["Deep work trend \(formatTrend(trend(deepWork)))."]
            ))
        }

        if let overload = lookup[.overloadPressure], let recovery = lookup[.recovery],
           average(overload) > 0.62, average(recovery) < 0.38 {
            observations.append(observation(
                id: "overload-low-recovery",
                severity: .severe,
                title: "Heavy days, little pause",
                detail: "Busy stretches ran long and there was not much quiet time to balance them.",
                confidence: min(overload.confidence, recovery.confidence),
                evidence: ["Load average \(formatAverage(average(overload))).", "Recovery average \(formatAverage(average(recovery)))."]
            ))
        }

        if let switching = lookup[.contextSwitching], average(switching) > 0.64 {
            observations.append(observation(
                id: "switching-high",
                severity: .elevated,
                title: "Switching took most of the day",
                detail: "You spent more time changing apps and tasks than staying in one flow.",
                confidence: switching.confidence,
                evidence: ["Switching average \(formatAverage(average(switching)))."]
            ))
        }

        if let passive = lookup[.passiveDecompression], let overload = lookup[.overloadPressure],
           trend(passive) > 0.16, average(overload) > 0.50 {
            observations.append(observation(
                id: "passive-after-overload",
                severity: .note,
                title: "More passive viewing after busy stretches",
                detail: "Listening and viewing picked up after a stretch of heavier work.",
                confidence: min(passive.confidence, overload.confidence),
                evidence: ["Passive viewing trend \(formatTrend(trend(passive))).", "Load average \(formatAverage(average(overload)))."]
            ))
        }

        if let rhythm = lookup[.rhythmStability], average(rhythm) > 0.62, let focus = lookup[.focusContinuity],
           average(focus) > 0.48 {
            observations.append(observation(
                id: "stable-continuity",
                severity: .note,
                title: "A steadier stretch",
                detail: "Focus tended to stay in similar kinds of work rather than jumping around.",
                confidence: min(rhythm.confidence, focus.confidence),
                evidence: ["Stability average \(formatAverage(average(rhythm))).", "Focus average \(formatAverage(average(focus)))."]
            ))
        }

        if observations.isEmpty {
            observations.append(observation(
                id: "no-hard-observation",
                severity: .note,
                title: "No strong read yet",
                detail: "Recent activity does not support one clear summary for this range.",
                confidence: maturity.confidenceCeiling,
                evidence: ["Signals stayed below the threshold for a firm note."]
            ))
        }

        return Array(observations.prefix(maturity >= .longHorizon ? 5 : 3))
    }

    private static func observation(
        id: String,
        severity: NoxObservatoryObservationSeverity,
        title: String,
        detail: String,
        confidence: Double,
        evidence: [String]
    ) -> NoxObservatoryObservation {
        NoxObservatoryObservation(
            id: id,
            severity: severity,
            title: title,
            detail: detail,
            confidence: min(max(confidence, 0), 1),
            evidence: evidence
        )
    }

    private static func average(_ series: NoxObservatorySignalSeries) -> Double {
        guard !series.values.isEmpty else { return 0 }
        return series.values.map(\.value).reduce(0, +) / Double(series.values.count)
    }

    private static func trend(_ series: NoxObservatorySignalSeries) -> Double {
        let values = series.values.map(\.value)
        guard values.count >= 4 else { return 0 }
        let midpoint = values.count / 2
        let first = values[..<midpoint].reduce(0, +) / Double(midpoint)
        let second = values[midpoint...].reduce(0, +) / Double(values.count - midpoint)
        return second - first
    }

    private static func formatAverage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func formatTrend(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(Int((value * 100).rounded()))%"
    }
}
