import Foundation
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

extension NoxObservatoryDataProvider {
    func buildSeries(
        from buckets: [NoxObservatoryBucket],
        bucketSeconds: TimeInterval,
        maturity: NoxObservatoryMaturityLevel
    ) -> [NoxObservatorySignalSeries] {
        var rawValues = Dictionary(uniqueKeysWithValues: NoxObservatorySignal.allCases.map { signal in
            (signal, buckets.map { raw(signal, bucket: $0, bucketSeconds: bucketSeconds) })
        })
        rawValues[.rhythmStability] = rhythmStabilityValues(
            focus: rawValues[.focusContinuity] ?? [],
            recovery: rawValues[.recovery] ?? [],
            overload: rawValues[.overloadPressure] ?? []
        )

        return NoxObservatorySignal.allCases.map { signal in
            let normalized = normalize(rawValues[signal] ?? [])
            let values = zip(buckets, normalized).map { bucket, value in
                NoxObservatoryPoint(
                    id: "\(signal.id)-\(bucket.index)",
                    timestamp: bucket.start,
                    value: value
                )
            }
            let nonZero = normalized.filter { $0 > 0.02 }.count
            let confidence = min(
                maturity.confidenceCeiling,
                Double(nonZero) / Double(max(1, buckets.count / 3))
            )
            return NoxObservatorySignalSeries(
                id: signal.id,
                signal: signal,
                values: values,
                confidence: min(max(confidence, 0.08), maturity.confidenceCeiling),
                isVisible: true,
                observationWeight: normalized.reduce(0, +) / Double(max(1, normalized.count))
            )
        }
    }

    func raw(_ signal: NoxObservatorySignal, bucket: NoxObservatoryBucket, bucketSeconds: TimeInterval) -> Double {
        let activeRatio = clamp(bucket.activeSeconds / bucketSeconds)
        let sustainedRatio = clamp(bucket.sustainedSemanticSeconds / max(bucket.semanticSeconds, 1))
        let focusContinuity = clamp(bucket.focusContinuitySeconds / max(bucket.focusBlockSeconds, 1))
        let lowSwitching = 1 - clamp(Double(bucket.switchEvents + bucket.focusSwitches) / 10)
        let lowInterruption = 1 - clamp(Double(bucket.interruptionEvents + bucket.interruptions) / 8)
        let longSpanContinuity = 1 - clamp(Double(bucket.shortSpanCount) / Double(max(1, bucket.spanCount)))
        let switching = clamp((Double(bucket.switchEvents) / 8) + (Double(bucket.appNames.count + bucket.categories.count) / 14))
        let fragmentation = clamp(
            (bucket.fragmentedSeconds / max(bucketSeconds, 1)) * 0.35
            + (bucket.fragmentedSemanticSeconds / max(bucket.semanticSeconds, 1)) * 0.25
            + (Double(bucket.shortSpanCount) / Double(max(1, bucket.spanCount))) * 0.25
            + (Double(bucket.interruptionEvents + bucket.interruptions) / 8) * 0.15
        )
        let deepWork = clamp(
            (bucket.deepWorkSeconds / max(bucketSeconds, 1)) * 0.45
            + (bucket.deepContextSeconds / max(bucketSeconds, 1)) * 0.35
            + focusContinuity * activeRatio * 0.20
        )
        let recovery = clamp(
            bucket.utilityRecovery * 0.30
            + (activeRatio < 0.08 ? 0.45 : 0)
            + (bucket.passiveSeconds > 0 && bucket.behavioralPressure > 0.25 ? 0.25 : 0)
        )
        let passive = clamp(
            bucket.utilityDecompression * 0.25
            + (bucket.passiveSeconds / max(bucketSeconds, 1)) * 0.75
        )
        let coordination = clamp(
            (bucket.communicationSeconds / max(bucketSeconds, 1)) * 0.70
            + bucket.cadencePressure * 0.30
        )
        let overload = clamp(
            deepWork * 0.24
            + coordination * 0.24
            + fragmentation * 0.24
            + (1 - recovery) * activeRatio * 0.20
            + bucket.behavioralPressure * 0.08
        )
        let interruption = clamp(Double(bucket.interruptionEvents + bucket.interruptions) / 8)

        switch signal {
        case .focusContinuity:
            return clamp(sustainedRatio * 0.30 + lowSwitching * 0.22 + lowInterruption * 0.20 + longSpanContinuity * activeRatio * 0.18 + focusContinuity * 0.10)
        case .deepWork: return deepWork
        case .fragmentation: return fragmentation
        case .contextSwitching: return switching
        case .recovery: return recovery
        case .passiveDecompression: return passive
        case .coordinationLoad: return coordination
        case .overloadPressure: return overload
        case .interruptionDensity: return interruption
        case .rhythmStability: return 0
        }
    }

    func normalize(_ values: [Double]) -> [Double] {
        guard !values.isEmpty else { return [] }
        let smoothed = smooth(values)
        let sorted = smoothed.sorted()
        let low = percentile(sorted, fraction: 0.08)
        let high = percentile(sorted, fraction: 0.92)
        guard high - low > 0.06 else {
            return smoothed.map { displayRange(clamp($0)) }
        }
        return smoothed.map { displayRange(clamp(($0 - low) / (high - low))) }
    }

    func rhythmStabilityValues(focus: [Double], recovery: [Double], overload: [Double]) -> [Double] {
        let count = min(focus.count, recovery.count, overload.count)
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            guard index > 0 else { return 0.5 }
            let volatility = abs(focus[index] - focus[index - 1])
                + abs(recovery[index] - recovery[index - 1])
                + abs(overload[index] - overload[index - 1])
            return clamp(1 - volatility / 2.2)
        }
    }
}
