import Foundation
import NoxSemanticCore
import NoxContextCore
import NoxCore

public struct NoxFocusInterruptionEngine {
  public init() {}

  private let fragmentedSwitchThreshold = 6
  private let fragmentedWindowMs = 22 * 60_000
  private let deepWorkMs = 45 * 60_000
  private let focusedMs = 20 * 60_000

    public func analyze(
        spans: [NoxActivitySpan],
        interruptions: [NoxInterruption],
        range: (start: Date, end: Date)
    ) -> (blocks: [NoxFocusBlock], live: NoxFocusAnalysis) {
        let sorted = spans.sorted { $0.startedAt < $1.startedAt }
        var blocks: [NoxFocusBlock] = []
        let windowStart = range.start
        let switchCount = max(0, sorted.count - 1)

        if switchCount >= fragmentedSwitchThreshold {
            let duration = min(fragmentedWindowMs, Int(range.end.timeIntervalSince(range.start) * 1000))
            blocks.append(
                NoxFocusBlock(
                    id: UUID().uuidString,
                    startedAt: windowStart,
                    endedAt: range.start.addingTimeInterval(Double(duration) / 1000),
                    primaryApp: "Multiple",
                    primaryBundleId: "fragmented",
                    durationMs: duration,
                    switchCount: switchCount,
                    intensity: 0.4,
                    continuityScore: 0.2,
                    kind: .fragmented
                )
            )
        }

        let workSpans = sorted.filter { $0.category.isWorkLike && $0.durationMs >= 5 * 60_000 }
        var cursor = 0
        while cursor < workSpans.count {
            let seed = workSpans[cursor]
            var end = seed.endedAt ?? range.end
            var switches = 0
            var index = cursor + 1
            while index < workSpans.count {
                let next = workSpans[index]
                let gap = next.startedAt.timeIntervalSince(end)
                if gap > 120 { break }
                switches += 1
                end = next.endedAt ?? end
                index += 1
            }
            let durationMs = max(0, Int(end.timeIntervalSince(seed.startedAt) * 1000))
            if durationMs >= focusedMs {
                let kind: NoxFocusBlockKind = durationMs >= deepWorkMs && switches <= 2 ? .deepWork : .focused
                blocks.append(
                    NoxFocusBlock(
                        id: UUID().uuidString,
                        startedAt: seed.startedAt,
                        endedAt: end,
                        primaryApp: seed.appName,
                        primaryBundleId: seed.bundleId,
                        durationMs: durationMs,
                        switchCount: switches,
                        intensity: kind == .deepWork ? 0.9 : 0.7,
                        continuityScore: max(0, 1.0 - Double(switches) * 0.15),
                        kind: kind
                    )
                )
            }
            cursor = max(cursor + 1, index)
        }

        let openSpan = sorted.last
        let uninterruptedMs = openSpan?.durationMs ?? 0
        let liveKind = blocks.last?.kind
        let live = NoxFocusAnalysis(
            kind: liveKind,
            uninterruptedMs: uninterruptedMs,
            switchCount: switchCount,
            continuityScore: blocks.last?.continuityScore ?? 0.5
        )
        return (blocks, live)
    }
}
