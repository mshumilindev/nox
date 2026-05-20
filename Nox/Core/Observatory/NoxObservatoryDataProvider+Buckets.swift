import Foundation

extension NoxObservatoryDataProvider {
    func applySnapshotOverlays(
        to buckets: inout [NoxObservatoryBucket],
        behavioralSnapshot: NoxBehavioralIntelligenceSnapshot,
        utilitySnapshot: NoxAmbientUtilitySnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot
    ) {
        let behavioralPressure = behavioralSnapshot.signatures.reduce(0.0) { partial, signature in
            switch signature.kind {
            case .overloadRecoveryOscillation, .fragmentedContext, .instabilityPhase:
                return max(partial, signature.confidence)
            default:
                return partial
            }
        }
        let cadencePressure = connectorSnapshot.cadencePatterns.reduce(0.0) { partial, pattern in
            max(partial, pattern.confidence)
        }
        let utilityRecovery = utilitySnapshot.recoveryWindow.isOpen ? utilitySnapshot.recoveryWindow.confidence : 0
        let utilityDecompression = utilitySnapshot.decompression.inDecompression ? utilitySnapshot.decompression.confidence : 0

        guard !buckets.isEmpty else { return }
        let tailStart = max(0, buckets.count - max(4, buckets.count / 5))
        for index in tailStart..<buckets.count {
            buckets[index].behavioralPressure = behavioralPressure
            buckets[index].cadencePressure = cadencePressure
            buckets[index].utilityRecovery = utilityRecovery
            buckets[index].utilityDecompression = utilityDecompression
        }
    }

    func overlappingBucketIndexes(
        start: Date,
        end: Date,
        rangeStart: Date,
        bucketSeconds: TimeInterval,
        count: Int
    ) -> Range<Int> {
        let lower = max(0, Int(floor(start.timeIntervalSince(rangeStart) / bucketSeconds)))
        let upper = min(count, Int(ceil(end.timeIntervalSince(rangeStart) / bucketSeconds)))
        return lower..<max(lower, upper)
    }

    func bucketIndex(
        for date: Date,
        rangeStart: Date,
        bucketSeconds: TimeInterval,
        count: Int
    ) -> Int? {
        let index = Int(floor(date.timeIntervalSince(rangeStart) / bucketSeconds))
        guard index >= 0, index < count else { return nil }
        return index
    }

    func overlapSeconds(startA: Date, endA: Date, startB: Date, endB: Date) -> TimeInterval {
        max(0, minDate(endA, endB).timeIntervalSince(maxDate(startA, startB)))
    }

    func minDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs < rhs ? lhs : rhs
    }

    func maxDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs > rhs ? lhs : rhs
    }

    func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    func smooth(_ values: [Double]) -> [Double] {
        guard values.count > 2 else { return values }
        return values.indices.map { index in
            let lower = max(values.startIndex, index - 2)
            let upper = min(values.index(before: values.endIndex), index + 2)
            let slice = values[lower...upper]
            return slice.reduce(0, +) / Double(slice.count)
        }
    }

    func percentile(_ sorted: [Double], fraction: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let index = Int((Double(sorted.count - 1) * clamp(fraction)).rounded())
        return sorted[min(max(index, 0), sorted.count - 1)]
    }

    func displayRange(_ value: Double) -> Double {
        0.10 + clamp(value) * 0.80
    }
}
