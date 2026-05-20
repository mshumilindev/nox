import Foundation
import NoxCore

/// Re-evaluates context while the foreground app stays the same.
@MainActor
public final class NoxContextHeartbeat {
    public init() {}
    private var lastBundleId: String?
    private var lastTitleFingerprint: String?
    private var lastPublishedLabel: String?
    private var lastEvaluationAt: Date?
    private let minimumInterval: TimeInterval = 1
    private let labelCooldown: TimeInterval = 3
    private var contextShiftPending = false

    public func markContextShift() {
        contextShiftPending = true
    }

    public func shouldEvaluate(
        snapshot: NoxActivitySnapshot,
        evidence: NoxContextEvidence,
        now: Date = Date()
    ) -> Bool {
        if contextShiftPending { return true }

        if let lastEvaluationAt, now.timeIntervalSince(lastEvaluationAt) < minimumInterval {
            return false
        }

        let titleKey = snapshot.windowTitle ?? ""
        let contextShift = lastBundleId != snapshot.bundleId
            || lastTitleFingerprint != titleKey
            || evidence.activity.stableDurationSeconds.truncatingRemainder(dividingBy: 10) < 1

        return contextShift || evidence.semantic.staleIgnored.count > 0
    }

    public func shouldPublishLabel(_ label: String, now: Date = Date()) -> Bool {
        if contextShiftPending { return true }
        if lastPublishedLabel == label { return false }
        if let lastEvaluationAt, now.timeIntervalSince(lastEvaluationAt) < labelCooldown {
            return lastPublishedLabel == nil
        }
        return true
    }

    public func recordEvaluation(
        snapshot: NoxActivitySnapshot,
        label: String,
        now: Date = Date()
    ) {
        lastBundleId = snapshot.bundleId
        lastTitleFingerprint = snapshot.windowTitle
        lastPublishedLabel = label
        lastEvaluationAt = now
        contextShiftPending = false
    }

    public func reset() {
        lastBundleId = nil
        lastTitleFingerprint = nil
        lastPublishedLabel = nil
        lastEvaluationAt = nil
        contextShiftPending = false
    }
}
