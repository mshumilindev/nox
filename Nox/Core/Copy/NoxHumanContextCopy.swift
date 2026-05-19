import Foundation

/// Life-work-rest balanced UI language — attention and context, not productivity telemetry.
nonisolated enum NoxHumanContextCopy {

    // MARK: - Fragmented / mixed attention

    static let fragmentedAttentionPeriod = "Fragmented attention period"
    static let fragmentedWorkflowPeriod = "Fragmented workflow period"
    static let severalContextsInMotion = "Several contexts in motion"
    static let switchingBetweenContexts = "Switching between contexts"
    static let mixedContextPeriod = "Mixed context period"

    static func fragmentedLabel(workLike: Bool) -> String {
        workLike ? fragmentedWorkflowPeriod : fragmentedAttentionPeriod
    }

    // MARK: - Presence / session

    static func appInFocus(appName: String, minutes: Int) -> String {
        "\(appName) has been in focus for \(minutes)m"
    }

    static func appWasInFocus(appName: String, minutes: Int) -> String {
        "\(appName) was in focus for \(minutes)m"
    }

    static func steadyContext(minutes: Int) -> String {
        "A steady context for \(minutes)m"
    }

    static func focusedInApp(_ appName: String) -> String {
        "Focused in \(appName)"
    }

    // MARK: - Resumed / motion

    static let backInMotion = "Back in motion"
    static let contextResumed = "Context resumed"
    static let activeAgain = "Active again"

    // MARK: - Memory emergence

    static let todayBeginningToTakeShape = "Today is beginning to take shape."
    static let recentContextSettling = "Recent context is beginning to settle."
    static let shapeOfTodayEmerging = "The shape of today is emerging."
    static let contextsGathering = "Today's contexts are beginning to gather."

  // MARK: - Live / observing

    static let watchingQuietly = "Watching quietly"
    static let contextSettlingIntoMemory = "Recent context is beginning to settle into memory"

    // MARK: - Development gating

    static func isWorkLikeContext(_ inference: NoxSemanticInference) -> Bool {
        switch inference.fusionLabel {
        case .likelyWorkRelated, .likelyAIAssistedWork, .likelyCreativeWork:
            return true
        default:
            break
        }
        switch inference.state {
        case .writing:
            return inference.browserCategory == .development || inference.browserCategory == .reference
        case .sustainedInteraction:
            return inference.browserCategory == .development
        case .fragmentedInteraction:
            return inference.browserCategory == .development || inference.browserCategory == .reference
        default:
            return false
        }
    }

    /// Strong multi-signal development — not merely "Cursor is open".
    static func hasStrongDevelopmentEvidence(
        inference: NoxSemanticInference,
        appName: String?
    ) -> Bool {
        var score = 0
        if inference.browserCategory == .development { score += 1 }
        if inference.browserCategory == .reference { score += 1 }
        switch inference.aiWorkflow {
        case .codeOriented, .iterativeWorkflow: score += 2
        case .promptWriting: score += 1
        default: break
        }
        if let appName {
            let lower = appName.lowercased()
            if lower.contains("terminal") || lower.contains("xcode") { score += 1 }
            if lower.contains("github") { score += 1 }
        }
        return score >= 2
    }

    static func editorFocusLabel(appName: String?) -> String? {
        guard let appName, !appName.isEmpty else { return nil }
        let knownEditors = ["Cursor", "Xcode", "Code", "VS Code", "Terminal", "Warp", "iTerm", "Nova"]
        if knownEditors.contains(where: { appName.localizedCaseInsensitiveContains($0) }) {
            return focusedInApp(appName)
        }
        return nil
    }

    static func developmentDisplayLabel(
        inference: NoxSemanticInference?,
        appName: String?
    ) -> String {
        if let inference, hasStrongDevelopmentEvidence(inference: inference, appName: appName) {
            if inference.fusionLabel == .likelyAIAssistedWork || inference.aiWorkflow != nil {
                return "AI-assisted development"
            }
            return "Development context"
        }
        if let focus = editorFocusLabel(appName: appName) {
            return focus
        }
        return "Development context"
    }
}
