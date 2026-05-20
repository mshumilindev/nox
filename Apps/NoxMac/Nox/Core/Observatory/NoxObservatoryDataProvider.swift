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

@MainActor
final class NoxObservatoryDataProvider {
    private let timelineStore: NoxTimelineStore
    private let memoryCoordinator: NoxMemoryCoordinator

    init(
        timelineStore: NoxTimelineStore,
        memoryCoordinator: NoxMemoryCoordinator
    ) {
        self.timelineStore = timelineStore
        self.memoryCoordinator = memoryCoordinator
    }

    func snapshot(
        range: NoxObservatoryTimeRange,
        behavioralSnapshot: NoxBehavioralIntelligenceSnapshot,
        utilitySnapshot: NoxAmbientUtilitySnapshot,
        memoryEvolutionSnapshot: NoxMemoryEvolutionSnapshot,
        connectorSnapshot: NoxConnectorContinuitySnapshot,
        at now: Date = Date()
    ) async -> NoxObservatorySnapshot {
        let broadStart = now.addingTimeInterval(-180 * 24 * 3600)
        let broadSpans = (try? await memoryCoordinator.activitySpans(from: broadStart, to: now)) ?? []
        let earliest = broadSpans.map(\.startedAt).min()
        var dateRange = range.dateRange(now: now, earliest: earliest)
        if range == .allTime, dateRange.start >= dateRange.end {
            dateRange.start = now.addingTimeInterval(-24 * 3600)
        }

        let duration = max(1, dateRange.end.timeIntervalSince(dateRange.start))
        let bucketSize = NoxObservatoryBucketSize.fitting(duration: duration)
        let bucketSeconds = bucketSize.rawValue
        let spans = range == .allTime
            ? broadSpans
            : ((try? await memoryCoordinator.activitySpans(from: dateRange.start, to: dateRange.end)) ?? [])
        let semanticLimit = min(10_000, max(240, Int(duration / bucketSeconds) * 8))
        let semanticSpans = (try? await memoryCoordinator.semanticSpans(
            from: dateRange.start,
            to: dateRange.end,
            limit: semanticLimit
        )) ?? []
        let focusBlocks = (try? await memoryCoordinator.focusBlocks(from: dateRange.start, to: dateRange.end)) ?? []
        let interruptions = (try? await memoryCoordinator.interruptions(from: dateRange.start, to: dateRange.end)) ?? []
        let timelineEvents = (try? await timelineStore.events(from: dateRange.start, to: dateRange.end)) ?? []

        let bucketCount = max(1, min(720, Int(ceil(duration / bucketSeconds))))
        var buckets = (0..<bucketCount).map { index in
            let start = dateRange.start.addingTimeInterval(Double(index) * bucketSeconds)
            return NoxObservatoryBucket(
                index: index,
                start: start,
                end: minDate(start.addingTimeInterval(bucketSeconds), dateRange.end)
            )
        }

        for span in spans {
            let end = span.endedAt ?? dateRange.end
            for index in overlappingBucketIndexes(start: span.startedAt, end: end, rangeStart: dateRange.start, bucketSeconds: bucketSeconds, count: bucketCount) {
                let overlap = overlapSeconds(startA: span.startedAt, endA: end, startB: buckets[index].start, endB: buckets[index].end)
                guard overlap > 0 else { continue }
                buckets[index].activeSeconds += overlap
                buckets[index].focusScoreSeconds += overlap * max(0, min(1, span.focusScore))
                buckets[index].interruptions += span.interruptions
                buckets[index].appNames.insert(span.appName)
                buckets[index].categories.insert(span.category)
                buckets[index].spanCount += 1
                buckets[index].shortSpanCount += span.durationMs < 5 * 60_000 ? 1 : 0
                if span.category.isWorkLike { buckets[index].workSeconds += overlap }
                if span.category == .development || span.category == .research || span.category == .creative {
                    buckets[index].deepContextSeconds += overlap
                }
                if span.category == .communication { buckets[index].communicationSeconds += overlap }
                if span.category == .passive || span.category == .entertainment { buckets[index].passiveSeconds += overlap }
            }
        }

        for semantic in semanticSpans {
            let end = semantic.endedAt ?? dateRange.end
            for index in overlappingBucketIndexes(start: semantic.startedAt, end: end, rangeStart: dateRange.start, bucketSeconds: bucketSeconds, count: bucketCount) {
                let overlap = overlapSeconds(startA: semantic.startedAt, endA: end, startB: buckets[index].start, endB: buckets[index].end)
                guard overlap > 0 else { continue }
                buckets[index].semanticSeconds += overlap
                buckets[index].semanticStates.insert(semantic.semanticState)
                buckets[index].fusionLabels.insert(semantic.fusionLabel)
                if semantic.semanticState == .sustainedInteraction || semantic.semanticState == .writing || semantic.semanticState == .reading {
                    buckets[index].sustainedSemanticSeconds += overlap
                }
                if semantic.semanticState == .fragmentedInteraction {
                    buckets[index].fragmentedSemanticSeconds += overlap
                }
                if semantic.fusionLabel == .likelyCommunication {
                    buckets[index].communicationSeconds += overlap * 0.5
                }
                if semantic.fusionLabel == .likelyPassiveEntertainment {
                    buckets[index].passiveSeconds += overlap
                }
                if semantic.fusionLabel == .likelyResearch || semantic.fusionLabel == .likelyAIAssistedWork || semantic.fusionLabel == .likelyCreativeWork {
                    buckets[index].deepContextSeconds += overlap * 0.65
                }
            }
        }

        for block in focusBlocks {
            for index in overlappingBucketIndexes(start: block.startedAt, end: block.endedAt, rangeStart: dateRange.start, bucketSeconds: bucketSeconds, count: bucketCount) {
                let overlap = overlapSeconds(startA: block.startedAt, endA: block.endedAt, startB: buckets[index].start, endB: buckets[index].end)
                guard overlap > 0 else { continue }
                buckets[index].focusBlockSeconds += overlap
                buckets[index].focusContinuitySeconds += overlap * max(0, min(1, block.continuityScore))
                buckets[index].focusSwitches += block.switchCount
                if block.kind == .deepWork { buckets[index].deepWorkSeconds += overlap }
                if block.kind == .fragmented { buckets[index].fragmentedSeconds += overlap }
            }
        }

        for interruption in interruptions {
            let index = bucketIndex(for: interruption.timestamp, rangeStart: dateRange.start, bucketSeconds: bucketSeconds, count: bucketCount)
            if let index {
                buckets[index].interruptionEvents += 1
            }
        }

        for event in timelineEvents where event.type == "app.changed" || event.type == "window.changed" {
            let index = bucketIndex(for: event.timestamp, rangeStart: dateRange.start, bucketSeconds: bucketSeconds, count: bucketCount)
            if let index {
                buckets[index].switchEvents += 1
            }
        }

        applySnapshotOverlays(
            to: &buckets,
            behavioralSnapshot: behavioralSnapshot,
            utilitySnapshot: utilitySnapshot,
            connectorSnapshot: connectorSnapshot
        )

        let observedSeconds = buckets.reduce(0) { $0 + min($1.activeSeconds + $1.semanticSeconds, bucketSeconds) }
        let maturity = NoxObservatoryMaturityLevel.from(observedSeconds: observedSeconds)
        let series = buildSeries(from: buckets, bucketSeconds: bucketSeconds, maturity: maturity)
        let observations = NoxObservatoryObservationEngine.observations(series: series, maturity: maturity)

        _ = memoryEvolutionSnapshot
        return NoxObservatorySnapshot(
            range: range,
            bucketSize: bucketSize,
            start: dateRange.start,
            end: dateRange.end,
            maturity: maturity,
            observedSeconds: observedSeconds,
            series: series,
            observations: observations,
            generatedAt: now
        )
    }

}
