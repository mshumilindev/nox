import Foundation

enum NoxContinuityResurfacingPresenter {

    static func resurfacing(
        for thread: NoxContinuityThread,
        match: NoxContinuityMatchResult?,
        at date: Date = Date()
    ) -> NoxContinuityResurfacing? {
        guard NoxContinuityDecay.canResurface(thread, at: date) else { return nil }
        guard thread.confidence >= NoxContinuityConfidence.resurfaceThreshold else { return nil }

        let primary = primaryText(for: thread, isResumption: match?.isResumption == true)
        let secondary = secondaryText(for: thread, at: date)

        return NoxContinuityResurfacing(
            threadId: thread.id,
            primaryText: primary,
            secondaryText: secondary,
            confidence: thread.confidence,
            timestamp: date
        )
    }

    static func threadDisplayTitle(_ thread: NoxContinuityThread) -> String {
        if thread.sensitivityLevel != .normal {
            return "Private continuity"
        }
        return thread.title
    }

    static func threadDetailLine(_ thread: NoxContinuityThread) -> String {
        if thread.sensitivityLevel != .normal {
            return "Generalized continuity only"
        }
        var parts: [String] = []
        if thread.totalResumptions > 0 {
            parts.append("\(thread.totalResumptions) resumption\(thread.totalResumptions == 1 ? "" : "s")")
        }
        if thread.totalSessions > 1 {
            parts.append("\(thread.totalSessions) sessions")
        }
        if !parts.isEmpty {
            return parts.joined(separator: " · ")
        }
        return recurrenceHint(thread)
    }

    private static func primaryText(for thread: NoxContinuityThread, isResumption: Bool) -> String {
        if thread.sensitivityLevel != .normal {
            return isResumption ? "Private continuity resumed" : "Private continuity"
        }
        let base = continuityNoun(for: thread.semanticType)
        return isResumption ? "\(base) resumed" : base
    }

    private static func continuityNoun(for type: NoxContinuitySemanticType) -> String {
        switch type {
        case .aiDevelopment: return "Development context"
        case .research: return "Research"
        case .travelPlanning: return "Travel planning"
        case .writing: return "Writing"
        case .development: return "Development context"
        case .fragmentedWorkflow: return NoxHumanContextCopy.fragmentedAttentionPeriod
        case .passiveViewing: return "Watching"
        case .privateContext, .sensitiveContext: return "Private context"
        case .general: return "Context continuity"
        }
    }

    private static func secondaryText(for thread: NoxContinuityThread, at date: Date) -> String? {
        let gap = date.timeIntervalSince(thread.lastSeenAt)
        if gap < 6 * 3600 {
            return "Previously active earlier today"
        }
        if gap < 36 * 3600 {
            return "Last active last night"
        }
        if thread.recurrenceStrength >= 0.45 {
            return "Seen repeatedly this week"
        }
        return nil
    }

    private static func recurrenceHint(_ thread: NoxContinuityThread) -> String {
        if thread.recurrenceStrength >= 0.5 {
            return "Recurring across multiple days"
        }
        if thread.totalResumptions >= 2 {
            return "Resumed several times"
        }
        return "Continuity across time"
    }
}
