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
                    title: "Low signal confidence",
                    detail: maturity.copy,
                    confidence: maturity.confidenceCeiling,
                    evidence: ["Observed activity is below the threshold for strong interpretation."]
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
                title: "Recovery is losing ground",
                detail: "Recovery periods are becoming shorter while coordination load remains elevated.",
                confidence: min(recovery.confidence, coordination.confidence),
                evidence: ["Recovery trend \(formatTrend(trend(recovery))).", "Coordination average \(formatAverage(average(coordination)))."]
            ))
        }

        if let fragmentation = lookup[.fragmentation], let focus = lookup[.focusContinuity],
           average(fragmentation) > 0.58, average(focus) < 0.46 {
            observations.append(observation(
                id: "fragmentation-dominates-focus",
                severity: .elevated,
                title: "Fragmentation is dominating focus",
                detail: "App switching remains elevated even during periods where sustained focus should carry more of the day.",
                confidence: min(fragmentation.confidence, focus.confidence),
                evidence: ["Fragmentation average \(formatAverage(average(fragmentation))).", "Focus continuity average \(formatAverage(average(focus)))."]
            ))
        }

        if let deepWork = lookup[.deepWork], trend(deepWork) < -0.18, maturity >= .normal {
            observations.append(observation(
                id: "deep-work-collapse",
                severity: .severe,
                title: "Deep work periods are dropping",
                detail: "Sustained deep work has decreased relative to the earlier part of this range.",
                confidence: deepWork.confidence,
                evidence: ["Deep work trend \(formatTrend(trend(deepWork)))."]
            ))
        }

        if let overload = lookup[.overloadPressure], let recovery = lookup[.recovery],
           average(overload) > 0.62, average(recovery) < 0.38 {
            observations.append(observation(
                id: "overload-low-recovery",
                severity: .severe,
                title: "Sustained overload pressure",
                detail: "Current rhythm suggests sustained overload. Recovery is consistently insufficient relative to workload.",
                confidence: min(overload.confidence, recovery.confidence),
                evidence: ["Overload average \(formatAverage(average(overload))).", "Recovery average \(formatAverage(average(recovery)))."]
            ))
        }

        if let switching = lookup[.contextSwitching], average(switching) > 0.64 {
            observations.append(observation(
                id: "switching-high",
                severity: .elevated,
                title: "Switching is taking the foreground",
                detail: "You are spending significantly more time switching than sustaining focus.",
                confidence: switching.confidence,
                evidence: ["Context switching average \(formatAverage(average(switching)))."]
            ))
        }

        if let passive = lookup[.passiveDecompression], let overload = lookup[.overloadPressure],
           trend(passive) > 0.16, average(overload) > 0.50 {
            observations.append(observation(
                id: "passive-after-overload",
                severity: .note,
                title: "Passive decompression is rising",
                detail: "Passive decompression increased sharply after prolonged overload.",
                confidence: min(passive.confidence, overload.confidence),
                evidence: ["Passive decompression trend \(formatTrend(trend(passive))).", "Overload average \(formatAverage(average(overload)))."]
            ))
        }

        if let rhythm = lookup[.rhythmStability], average(rhythm) > 0.62, let focus = lookup[.focusContinuity],
           average(focus) > 0.48 {
            observations.append(observation(
                id: "stable-continuity",
                severity: .note,
                title: "A stable activity window",
                detail: "Most sustained focus is clustering inside a stable rhythm rather than appearing randomly.",
                confidence: min(rhythm.confidence, focus.confidence),
                evidence: ["Rhythm stability average \(formatAverage(average(rhythm))).", "Focus continuity average \(formatAverage(average(focus)))."]
            ))
        }

        if observations.isEmpty {
            observations.append(observation(
                id: "no-hard-observation",
                severity: .note,
                title: "No strong conclusion",
                detail: "The collected signals do not justify a strong interpretation for this range.",
                confidence: maturity.confidenceCeiling,
                evidence: ["No signal crossed the confidence-gated observation thresholds."]
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
