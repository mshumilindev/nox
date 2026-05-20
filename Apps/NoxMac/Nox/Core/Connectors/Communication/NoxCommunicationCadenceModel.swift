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

struct NoxCommunicationCadenceSnapshot: Equatable, Sendable {
    let communicationMinutes: Int
    let communicationSpanCount: Int
    let burstWindows: Int
    let quietMinutes: Int
    let responseHeavyScore: Double

    static let empty = NoxCommunicationCadenceSnapshot(
        communicationMinutes: 0,
        communicationSpanCount: 0,
        burstWindows: 0,
        quietMinutes: 0,
        responseHeavyScore: 0
    )
}

enum NoxCommunicationCadenceModel {

    static func snapshot(
        spans: [NoxActivitySpan],
        range: (start: Date, end: Date),
        at date: Date = Date()
    ) -> NoxCommunicationCadenceSnapshot {
        let communicationSpans = spans.filter { $0.category == .communication }
        let minutes = communicationSpans.reduce(0) { $0 + max(0, $1.durationMs / 60_000) }
        let bursts = burstWindows(in: communicationSpans)
        let quiet = quietStretchMinutes(spans: spans, range: range, at: date)
        let responseScore = responseHeavyScore(
            communicationMinutes: minutes,
            switchCount: max(0, spans.count - 1)
        )

        return NoxCommunicationCadenceSnapshot(
            communicationMinutes: minutes,
            communicationSpanCount: communicationSpans.count,
            burstWindows: bursts,
            quietMinutes: quiet,
            responseHeavyScore: responseScore
        )
    }

    private static func burstWindows(in spans: [NoxActivitySpan]) -> Int {
        guard spans.count >= 2 else { return spans.isEmpty ? 0 : 1 }
        var bursts = 0
        var cluster = 1
        let sorted = spans.sorted { $0.startedAt < $1.startedAt }
        for index in 1..<sorted.count {
            let gap = sorted[index].startedAt.timeIntervalSince(
                sorted[index - 1].endedAt ?? sorted[index - 1].startedAt
            )
            if gap <= 20 * 60 {
                cluster += 1
            } else {
                if cluster >= 2 { bursts += 1 }
                cluster = 1
            }
        }
        if cluster >= 2 { bursts += 1 }
        return bursts
    }

    private static func quietStretchMinutes(
        spans: [NoxActivitySpan],
        range: (start: Date, end: Date),
        at date: Date
    ) -> Int {
        let recentCommunication = spans
            .filter { $0.category == .communication }
            .map { $0.endedAt ?? $0.startedAt }
            .max() ?? range.start
        return max(0, Int(date.timeIntervalSince(recentCommunication) / 60))
    }

    private static func responseHeavyScore(
        communicationMinutes: Int,
        switchCount: Int
    ) -> Double {
        guard communicationMinutes > 0 else { return 0 }
        let density = Double(communicationMinutes) / 120.0
        let switching = Double(switchCount) / 12.0
        return min(1.0, (density * 0.6) + (switching * 0.4))
    }
}
