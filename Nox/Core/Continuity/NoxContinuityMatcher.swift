import Foundation

enum NoxContinuityMatcher {
    private static let maxGapForResume: TimeInterval = 14 * 24 * 3600
    private static let minGapForResume: TimeInterval = 20 * 60

    static func bestMatch(
        signature: NoxContinuitySignature,
        candidates: [NoxContinuityThread],
        at date: Date,
        gapSinceLastActivity: TimeInterval?
    ) -> NoxContinuityMatchResult? {
        var best: NoxContinuityMatchResult?
        for candidate in candidates {
            let result = score(signature: signature, against: candidate, at: date, gap: gapSinceLastActivity)
            if result.totalScore >= NoxContinuityConfidence.matchThreshold {
                if best == nil || result.totalScore > best!.totalScore {
                    best = result
                }
            }
        }
        return best
    }

    static func score(
        signature: NoxContinuitySignature,
        against thread: NoxContinuityThread,
        at date: Date,
        gap: TimeInterval?
    ) -> NoxContinuityMatchResult {
        var components: [NoxContinuityMatchComponent] = []

        let ecosystemScore: Double
        if signature.ecosystemKey == thread.continuitySignature.ecosystemKey {
            ecosystemScore = 1.0
        } else if signature.semanticType == thread.semanticType {
            ecosystemScore = 0.72
        } else {
            ecosystemScore = 0.2
        }
        components.append(.init(name: "ecosystem", score: ecosystemScore, detail: "workflow shape overlap"))

        let semanticScore = signature.semanticType == thread.semanticType ? 1.0 : 0.35
        components.append(.init(name: "semantic", score: semanticScore, detail: "semantic type alignment"))

        let appOverlap = jaccard(signature.appTokens, thread.continuitySignature.appTokens)
        components.append(.init(name: "apps", score: appOverlap, detail: "app constellation overlap"))

        let temporalGap = gap ?? date.timeIntervalSince(thread.lastSeenAt)
        let temporalScore: Double
        if temporalGap < 30 * 60 {
            temporalScore = 0.55
        } else if temporalGap <= 6 * 3600 {
            temporalScore = 0.85
        } else if temporalGap <= 48 * 3600 {
            temporalScore = 1.0
        } else if temporalGap <= maxGapForResume {
            temporalScore = 0.75
        } else {
            temporalScore = 0.25
        }
        components.append(.init(name: "temporal", score: temporalScore, detail: "time since last activity"))

        let interactionScore = signature.interactionProfile == thread.continuitySignature.interactionProfile ? 1.0 : 0.5
        components.append(.init(name: "interaction", score: interactionScore, detail: "interaction pattern similarity"))

        let recurrenceScore = min(1.0, thread.recurrenceStrength + Double(thread.totalResumptions) * 0.05)
        components.append(.init(name: "recurrence", score: recurrenceScore, detail: "prior recurrence history"))

        let total = ecosystemScore * 0.32
            + semanticScore * 0.24
            + appOverlap * 0.16
            + temporalScore * 0.14
            + interactionScore * 0.08
            + recurrenceScore * 0.06

        let isResumption = temporalGap >= minGapForResume
            && temporalGap <= maxGapForResume
            && total >= NoxContinuityConfidence.resurfaceThreshold
            && ecosystemScore >= 0.72

        return NoxContinuityMatchResult(
            threadId: thread.id,
            totalScore: total,
            components: components,
            isResumption: isResumption
        )
    }

    private static func jaccard(_ a: [String], _ b: [String]) -> Double {
        let setA = Set(a)
        let setB = Set(b)
        guard !setA.isEmpty || !setB.isEmpty else { return 0 }
        let intersection = setA.intersection(setB).count
        let union = setA.union(setB).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }
}
