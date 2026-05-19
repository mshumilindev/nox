import Foundation

@MainActor
final class NoxMemoryAggregator {
    private let metadataExtractor = NoxMetadataExtractor()
    private(set) var openSpan: NoxActivitySpan?
    private var lastWorkSpan: NoxActivitySpan?
    private var pendingInterruption: (from: NoxActivitySpan, at: Date)?

    func ingestSnapshot(_ snapshot: NoxActivitySnapshot) -> NoxActivitySpan? {
        let metadata = metadataExtractor.extract(
            appName: snapshot.appName,
            bundleId: snapshot.bundleId,
            windowTitle: snapshot.windowTitle
        )
        if var current = openSpan, current.bundleId == snapshot.bundleId {
            current.endedAt = snapshot.capturedAt
            if metadata.contextLabel != nil {
                openSpan = NoxActivitySpan(
                    id: current.id,
                    startedAt: current.startedAt,
                    endedAt: current.endedAt,
                    appName: current.appName,
                    bundleId: current.bundleId,
                    windowTitle: snapshot.windowTitle,
                    contextLabel: metadata.contextLabel,
                    category: metadata.category,
                    interruptions: current.interruptions,
                    focusScore: current.focusScore,
                    metadataJson: encodeMetadata(metadata)
                )
            } else {
                openSpan = current
            }
            return openSpan
        }

        if let previous = openSpan {
            closeOpenSpan(at: snapshot.capturedAt)
        }

        let span = NoxActivitySpan(
            id: UUID().uuidString,
            startedAt: snapshot.capturedAt,
            endedAt: nil,
            appName: snapshot.appName,
            bundleId: snapshot.bundleId,
            windowTitle: snapshot.windowTitle,
            contextLabel: metadata.contextLabel,
            category: metadata.category,
            interruptions: 0,
            focusScore: metadata.category.isWorkLike ? 0.6 : 0.2,
            metadataJson: encodeMetadata(metadata)
        )
        openSpan = span
        if metadata.category.isWorkLike {
            lastWorkSpan = span
        }
        return span
    }

    func ingestAppChange(
        from previous: NoxActivitySnapshot?,
        to current: NoxActivitySnapshot,
        at date: Date
    ) -> (closedSpan: NoxActivitySpan?, interruption: NoxInterruption?) {
        var closed: NoxActivitySpan?
        if let openSpan {
            var finished = openSpan
            finished.endedAt = date
            closed = finished
            self.openSpan = nil
        }

        var interruption: NoxInterruption?
        if let previous, let lastWork = lastWorkSpan, lastWork.bundleId == previous.bundleId {
            let metadata = metadataExtractor.extract(
                appName: current.appName,
                bundleId: current.bundleId,
                windowTitle: current.windowTitle
            )
            if !metadata.category.isWorkLike {
                pendingInterruption = (lastWork, date)
            }
        }

        if let pending = pendingInterruption,
           pending.from.bundleId == current.bundleId {
            interruption = NoxInterruption(
                id: UUID().uuidString,
                timestamp: pending.at,
                fromApp: pending.from.appName,
                fromBundleId: pending.from.bundleId,
                toApp: current.appName,
                toBundleId: current.bundleId,
                durationMs: max(0, Int(date.timeIntervalSince(pending.at) * 1000)),
                returnedBack: true
            )
            if var closedSpan = closed, closedSpan.id == pending.from.id {
                closedSpan.interruptions += 1
                closed = closedSpan
            }
            pendingInterruption = nil
        }

        _ = ingestSnapshot(current)
        return (closed, interruption)
    }

    func closeOpenSpan(at date: Date) -> NoxActivitySpan? {
        guard var span = openSpan else { return nil }
        span.endedAt = date
        openSpan = nil
        return span
    }

    func restoreOpenSpan(_ span: NoxActivitySpan) {
        guard span.endedAt == nil else { return }
        openSpan = span
        if span.category.isWorkLike {
            lastWorkSpan = span
        }
    }

    private func encodeMetadata(_ metadata: NoxContextMetadata) -> String? {
        guard let data = try? JSONEncoder().encode(metadata) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
