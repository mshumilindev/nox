import Foundation
import NoxCore

public struct NoxContextDebugSnapshot: Equatable, Sendable {
    public let activeApp: String
    public let bundleId: String
    public let processId: String
    public let windowTitle: String?
    public let browserURL: String?
    public let browserDomain: String?
    public let browserPageTitle: String?
    public let adapterUsed: String
    public let adaptersInvoked: [String]
    public let acquisitionLevel: String
    public let capabilitiesAvailable: [String]
    public let capabilitiesMissing: [String]
    public let observationStatuses: [String]
    public let evidenceItems: [String]
    public let interactionShape: String
    public let candidates: [String]
    public let confidenceComponents: [String]
    public let dominantContext: String?
    public let secondaryContexts: [String]
    public let staleIgnored: [String]
    public let sensitivityDecision: String
    public let redactionReason: String?
    public let safeDisplayLabel: String
    public let safeSubtitle: String?
    public let reasons: [String]
    public let freshnessSeconds: TimeInterval
    public let runtimeIdentity: String
}

public enum NoxContextDebugFormatter {
    public static func make(
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
