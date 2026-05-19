import Foundation

enum NoxTimelineBlockPresenter {

    static func makeSections(
        spans: [NoxActivitySpan],
        focusBlocks: [NoxFocusBlock],
        interruptions: [NoxInterruption],
        semanticSpans: [NoxSemanticMemorySpan] = [],
        continuityThreads: [NoxContinuityThread] = []
    ) -> [NoxTimelineSection] {
        let stitched = NoxSemanticSpanStitcher.stitch(semanticSpans)
        let threadSpanIds = Set(continuityThreads.flatMap(\.linkedSpanIds))

        let continuityItems = continuityThreads.prefix(6).map(continuityItem)
        let semanticItems = stitched
            .prefix(8)
            .filter { !threadSpanIds.contains($0.id) }
            .map(semanticItem)
        let focusItems = focusBlocks.prefix(4).map(focusItem)
        let dedupedActivity = NoxTimelineActivityDeduper.filter(
            activitySpans: spans.filter { !$0.category.excludedFromAnalysis },
            semanticSpans: stitched
        )
        let activityItems = dedupedActivity.prefix(12).map(spanItem)
        let interruptionItems = interruptions.prefix(4).map(interruptionItem)

        let buckets: [NoxTimelineLayer: [NoxTimelineBlockItem]] = [
            .continuity: continuityItems,
            .semantic: semanticItems,
            .focus: focusItems,
            .activity: activityItems,
            .interruption: interruptionItems
        ]

        return NoxTimelineLayer.displayOrder.compactMap { layer in
            let items = (buckets[layer] ?? []).sorted { $0.timestamp > $1.timestamp }
            guard !items.isEmpty else { return nil }
            return NoxTimelineSection(layer: layer, items: items)
        }
    }

    static func makeBlocks(
        spans: [NoxActivitySpan],
        focusBlocks: [NoxFocusBlock],
        interruptions: [NoxInterruption],
        semanticSpans: [NoxSemanticMemorySpan] = [],
        continuityThreads: [NoxContinuityThread] = []
    ) -> [NoxTimelineBlockItem] {
        makeSections(
            spans: spans,
            focusBlocks: focusBlocks,
            interruptions: interruptions,
            semanticSpans: semanticSpans,
            continuityThreads: continuityThreads
        ).flatMap(\.items)
    }

    private static func continuityItem(_ thread: NoxContinuityThread) -> NoxTimelineBlockItem {
        let title = NoxContinuityResurfacingPresenter.threadDisplayTitle(thread)
        let detail = NoxContinuityResurfacingPresenter.threadDetailLine(thread)
        let subtitle = thread.dominantApps.isEmpty
            ? nil
            : NoxSemanticLabelCatalog.memorySubtitle(appNames: thread.dominantApps)
        return NoxTimelineBlockItem(
            id: thread.id,
            timestamp: thread.lastSeenAt,
            kind: .continuityThread(thread),
            title: title,
            subtitle: subtitle,
            detailLine: detail.isEmpty ? nil : detail,
            durationText: thread.durationText,
            category: nil,
            markerSymbol: "link"
        )
    }

    private static func focusItem(_ block: NoxFocusBlock) -> NoxTimelineBlockItem {
        let title = NoxSemanticLabelCatalog.focusBlockTitle(kind: block.kind)
        let subtitle: String
        switch block.kind {
        case .fragmented:
            subtitle = "\(block.switchCount) app switches · \(formatDuration(ms: block.durationMs))"
        default:
            subtitle = block.primaryApp
        }
        return NoxTimelineBlockItem(
            id: block.id,
            timestamp: block.startedAt,
            kind: .focusBlock(block),
            title: title,
            subtitle: subtitle,
            detailLine: block.kind == .fragmented ? "Scattered attention" : "Steady continuity",
            durationText: formatDuration(ms: block.durationMs),
            category: .development,
            markerSymbol: block.kind == .fragmented ? "arrow.triangle.branch" : "scope"
        )
    }

    private static func semanticItem(_ span: NoxSemanticMemorySpan) -> NoxTimelineBlockItem {
        let detail = NoxSemanticLabelCatalog.memoryDetail(inference: nil, span: span)
        let inProgress = span.endedAt == nil
        return NoxTimelineBlockItem(
            id: span.id,
            timestamp: span.startedAt,
            kind: .semanticSpan(span),
            title: inProgress ? "\(span.title) · forming" : span.title,
            subtitle: span.subtitle,
            detailLine: detail.isEmpty ? nil : detail,
            durationText: formatDuration(ms: span.durationMs),
            category: nil,
            markerSymbol: "sparkles"
        )
    }

    private static func spanItem(_ span: NoxActivitySpan) -> NoxTimelineBlockItem {
        let subtitle = NoxSemanticLabelCatalog.activitySpanSubtitle(
            appName: span.appName,
            contextLabel: span.contextLabel
        )
        return NoxTimelineBlockItem(
            id: span.id,
            timestamp: span.startedAt,
            kind: .activitySpan(span),
            title: span.category.displayName,
            subtitle: subtitle,
            detailLine: nil,
            durationText: formatDuration(ms: span.durationMs),
            category: span.category,
            markerSymbol: "app"
        )
    }

    private static func interruptionItem(_ item: NoxInterruption) -> NoxTimelineBlockItem {
        NoxTimelineBlockItem(
            id: item.id,
            timestamp: item.timestamp,
            kind: .interruption(item),
            title: "Brief interruption",
            subtitle: "\(item.fromApp) → \(item.toApp)",
            detailLine: nil,
            durationText: formatDuration(ms: item.durationMs),
            category: .communication,
            markerSymbol: "arrow.left.arrow.right"
        )
    }

    private static func formatDuration(ms: Int) -> String {
        let minutes = ms / 60_000
        if minutes >= 60 {
            let hours = minutes / 60
            let rem = minutes % 60
            return rem == 0 ? "\(hours)h" : "\(hours)h \(rem)m"
        }
        return "\(max(1, minutes))m"
    }
}
