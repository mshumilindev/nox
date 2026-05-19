import Foundation

struct NoxContextDebugSnapshot: Equatable, Sendable {
    let activeApp: String
    let bundleId: String
    let processId: String
    let windowTitle: String?
    let browserURL: String?
    let browserDomain: String?
    let browserPageTitle: String?
    let adapterUsed: String
    let adaptersInvoked: [String]
    let acquisitionLevel: String
    let capabilitiesAvailable: [String]
    let capabilitiesMissing: [String]
    let observationStatuses: [String]
    let evidenceItems: [String]
    let interactionShape: String
    let candidates: [String]
    let confidenceComponents: [String]
    let dominantContext: String?
    let secondaryContexts: [String]
    let staleIgnored: [String]
    let sensitivityDecision: String
    let redactionReason: String?
    let safeDisplayLabel: String
    let safeSubtitle: String?
    let reasons: [String]
    let freshnessSeconds: TimeInterval
    let runtimeIdentity: String
}

enum NoxContextDebugFormatter {
    static func make(
        evidence: NoxContextEvidence,
        runtimeIdentity: String = NoxDevRuntimeIdentity.permissionTargetSummary
    ) -> NoxContextDebugSnapshot {
        let ctx = evidence.appContext

        let observationLines = ctx.observationStatuses.map { status in
            status.isAvailable
                ? "✓ \(status.channel.displayName)"
                : "✗ \(status.channel.displayName): \(status.blocker ?? "unavailable")"
        }

        let evidenceLines = evidence.evidenceItems.map { item in
            "[\(item.source.rawValue)/\(item.kind.rawValue)] \(item.value) — \(item.explanation)"
        }

        let candidates = evidence.semantic.candidates.map {
            "\($0.contextType.rawValue) \(Int($0.confidence * 100))% (\($0.sourceAdapterId))"
        }

        let confidenceComponents = evidence.semantic.candidates.map {
            "\($0.contextType.rawValue) w=\(String(format: "%.2f", $0.dominanceWeight))"
        }

        return NoxContextDebugSnapshot(
            activeApp: ctx.appName,
            bundleId: ctx.bundleId,
            processId: ctx.processId.map(String.init) ?? "—",
            windowTitle: ctx.windowTitle,
            browserURL: ctx.documentURL,
            browserDomain: ctx.browserDomain,
            browserPageTitle: ctx.browserPageTitle,
            adapterUsed: ctx.primaryAdapterId,
            adaptersInvoked: ctx.adapterIds,
            acquisitionLevel: evidence.capability.acquisitionLevel.rawValue,
            capabilitiesAvailable: observationLines.filter { $0.hasPrefix("✓") },
            capabilitiesMissing: ctx.missingChannels.map(\.displayName),
            observationStatuses: observationLines,
            evidenceItems: evidenceLines,
            interactionShape: ctx.interactionShapeSummary,
            candidates: candidates,
            confidenceComponents: confidenceComponents,
            dominantContext: evidence.semantic.dominant?.contextType.rawValue,
            secondaryContexts: evidence.semantic.secondary.map(\.contextType.rawValue),
            staleIgnored: evidence.semantic.staleIgnored.map(\.contextType.rawValue),
            sensitivityDecision: ctx.sensitivity.rawValue,
            redactionReason: evidence.safeOutput.redactionReason,
            safeDisplayLabel: evidence.safeOutput.displayLabel,
            safeSubtitle: evidence.safeOutput.subtitle,
            reasons: evidence.semantic.reasons.map { "\($0.category): \($0.detail)" },
            freshnessSeconds: evidence.capability.extractionFreshnessSeconds,
            runtimeIdentity: runtimeIdentity
        )
    }
}
