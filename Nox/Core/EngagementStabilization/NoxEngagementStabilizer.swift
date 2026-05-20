import Foundation

struct NoxEngagementStabilizer {
    private var currentSnapshot: NoxActivitySnapshot?
    private var foregroundStartedAt: Date?
    private var currentPhase: NoxEngagementPhase = .rawForeground
    private var lastHardBundleId: String?
    private var continuityWindow = NoxContinuityStabilizationWindow()
    private var wandering = NoxWanderingAggregationEngine()

    mutating func ingest(
        snapshot: NoxActivitySnapshot,
        metrics: NoxInteractionMetrics
    ) -> NoxStabilizationDecision {
        let previousSnapshot = currentSnapshot
        let switched = previousSnapshot?.bundleId != snapshot.bundleId
        let previousState = switched ? closePrevious(at: snapshot.capturedAt, nextSnapshot: snapshot) : nil

        if switched {
            currentSnapshot = snapshot
            foregroundStartedAt = snapshot.capturedAt
            currentPhase = .rawForeground
            NoxEngagementDebug.log("raw foreground: \(snapshot.appName)")
        } else if currentSnapshot == nil {
            currentSnapshot = snapshot
            foregroundStartedAt = snapshot.capturedAt
        } else {
            currentSnapshot = snapshot
        }

        let intent = NoxForegroundIntentModel.intent(for: snapshot)
        let startedAt = foregroundStartedAt ?? snapshot.capturedAt
        let duration = max(0, snapshot.capturedAt.timeIntervalSince(startedAt))
        let interaction = NoxTransientTraversalFilter.interactionStrength(from: metrics)
        let phase = phaseForCurrent(
            duration: duration,
            interactionStrength: interaction,
            intent: intent
        )

        let becameSoft = currentPhase != .softStabilized
            && currentPhase != .hardStabilized
            && phase == .softStabilized
        let becameHard = currentPhase != .hardStabilized && phase == .hardStabilized
        currentPhase = phase

        let state = NoxEngagementState(
            phase: phase,
            snapshot: snapshot,
            foregroundStartedAt: startedAt,
            observedAt: snapshot.capturedAt,
            foregroundDuration: duration,
            interactionStrength: interaction,
            intent: intent,
            debugReason: "duration \(duration.formattedSeconds), interaction \(interaction.formattedRatio)"
        )

        var merge: NoxContinuityMerge?
        if becameSoft {
            NoxEngagementDebug.log("soft stabilization: \(snapshot.appName), \(duration.formattedSeconds)")
        }
        if becameHard {
            merge = continuityWindow.recordHardStabilization(state)
            lastHardBundleId = snapshot.bundleId
            wandering.reset()
            NoxEngagementDebug.log("hard stabilization: \(snapshot.appName), \(duration.formattedSeconds)")
            if let merge {
                NoxEngagementDebug.log("continuity merge: \(merge.absorbedTraversalCount) traversal(s), \(merge.totalTraversalSeconds.formattedSeconds)")
            }
        }

        let wanderingState = wandering.observe(state)
        if wanderingState != nil {
            NoxEngagementDebug.log("wandering aggregation: \(state.debugReason)")
        }

        return NoxStabilizationDecision(
            state: state,
            becameSoft: becameSoft,
            becameHard: becameHard,
            closedTransient: previousState?.isTransient == true ? previousState : nil,
            wanderingState: wanderingState,
            continuityMerge: merge
        )
    }

    var isCurrentHardStabilized: Bool {
        currentPhase == .hardStabilized
    }

    var currentStableDuration: TimeInterval {
        guard let started = foregroundStartedAt else { return 0 }
        return max(0, Date().timeIntervalSince(started))
    }

    private mutating func closePrevious(
        at date: Date,
        nextSnapshot: NoxActivitySnapshot
    ) -> NoxEngagementState? {
        guard let previous = currentSnapshot, let started = foregroundStartedAt else { return nil }
        let duration = max(0, date.timeIntervalSince(started))
        let intent = NoxForegroundIntentModel.intent(for: previous)
        let transient = currentPhase == .rawForeground
            && NoxTransientTraversalFilter.isTransient(
                duration: duration,
                interactionStrength: 0,
                intent: intent,
                nextSnapshot: nextSnapshot
            )
        let phase: NoxEngagementPhase = transient ? .transientTraversal : currentPhase
        let state = NoxEngagementState(
            phase: phase,
            snapshot: previous,
            foregroundStartedAt: started,
            observedAt: date,
            foregroundDuration: duration,
            interactionStrength: 0,
            intent: intent,
            debugReason: transient ? "closed as transient traversal" : "closed foreground"
        )
        if transient {
            continuityWindow.recordTransient(state)
            NoxEngagementDebug.log("transient traversal: \(previous.appName), \(duration.formattedSeconds)")
        }
        return state
    }

    private func phaseForCurrent(
        duration: TimeInterval,
        interactionStrength: Double,
        intent: NoxForegroundIntent
    ) -> NoxEngagementPhase {
        if interactionStrength >= 0.58, duration >= 1.2 {
            return .hardStabilized
        }
        if interactionStrength >= 0.34, duration >= 0.7 {
            return .softStabilized
        }
        if duration >= intent.hardThreshold {
            return .hardStabilized
        }
        if duration >= intent.softThreshold {
            return .softStabilized
        }
        return .rawForeground
    }
}

enum NoxEngagementDebug {
    static func log(_ line: String) {
        #if DEBUG
        print("[NoxEngagement] \(line)")
        #endif
    }
}

private extension TimeInterval {
    var formattedSeconds: String {
        String(format: "%.1fs", self)
    }
}

private extension Double {
    var formattedRatio: String {
        String(format: "%.2f", self)
    }
}
