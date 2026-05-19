import Foundation

enum NoxContextEvidenceAssembler {
    static func assemble(
        snapshot: NoxActivitySnapshot,
        capabilities: NoxCapabilityState,
        capabilityProfile: NoxContextCapabilityProfile,
        sensitivity: NoxSensitivityLevel,
        domain: String?,
        sanitizedTitle: String?,
        family: NoxAppFamily,
        metrics: NoxInteractionMetrics,
        stableDurationSeconds: TimeInterval,
        adapterEvidence: [NoxContextAdapterEvidence],
        resolution: NoxDominantContextResolver.Resolution,
        safeOutput: NoxSafeContextOutput,
        evaluatedAt: Date
    ) -> (items: [NoxContextEvidenceItem], appContext: NoxAppContext) {
        let freshness = max(0, evaluatedAt.timeIntervalSince(snapshot.capturedAt))
        var items: [NoxContextEvidenceItem] = []

        items.append(
            NoxContextEvidenceItem(
                source: .system,
                kind: .foregroundApp,
                value: "\(snapshot.appName) (\(snapshot.bundleId))",
                confidence: 1,
                freshnessSeconds: freshness,
                explanation: "Frontmost application from NSWorkspace"
            )
        )

        if let processId = snapshot.processId {
            items.append(
                NoxContextEvidenceItem(
                    source: .system,
                    kind: .foregroundApp,
                    value: "pid \(processId)",
                    confidence: 1,
                    freshnessSeconds: freshness,
                    explanation: "Process identifier"
                )
            )
        }

        if let title = sanitizedTitle, !title.isEmpty {
            items.append(
                NoxContextEvidenceItem(
                    source: .system,
                    kind: .windowTitle,
                    value: title,
                    confidence: capabilityProfile.windowAware ? 0.9 : 0.5,
                    freshnessSeconds: freshness,
                    sensitivityRisk: sensitivity,
                    explanation: capabilityProfile.windowAware
                        ? "Focused window title (sanitized)"
                        : "App-level title estimate"
                )
            )
        }

        if let documentURL = snapshot.documentURL, !documentURL.isEmpty, sensitivity == .normal {
            items.append(
                NoxContextEvidenceItem(
                    source: .system,
                    kind: .browserURL,
                    value: documentURL,
                    confidence: 0.92,
                    freshnessSeconds: freshness,
                    explanation: "Document URL from Accessibility kAXDocument"
                )
            )
        }

        if let domain, !domain.isEmpty, sensitivity == .normal {
            items.append(
                NoxContextEvidenceItem(
                    source: .system,
                    kind: .browserDomain,
                    value: domain,
                    confidence: 0.88,
                    freshnessSeconds: freshness,
                    explanation: "Host derived from URL or title"
                )
            )
        }

        let interactionSummary = interactionShape(metrics: metrics, snapshot: snapshot)
        items.append(
            NoxContextEvidenceItem(
                source: .interaction,
                kind: .interactionShape,
                value: interactionSummary,
                confidence: capabilityProfile.interactionSignalsAvailable ? 0.85 : 0.45,
                freshnessSeconds: freshness,
                explanation: "Rolling interaction metrics (no content)"
            )
        )

        for missing in NoxContextObservationMatrix.missingChannels(
            from: NoxContextObservationMatrix.build(
                snapshot: snapshot,
                capabilities: capabilities,
                domain: domain,
                documentURL: snapshot.documentURL,
                browserFamily: family == .browser,
                mediaFamily: family == .mediaPlayer
            )
        ) {
            items.append(
                NoxContextEvidenceItem(
                    source: .permission,
                    kind: .capability,
                    value: "missing: \(missing.displayName)",
                    confidence: 1,
                    freshnessSeconds: freshness,
                    explanation: "Capability not available for this observation"
                )
            )
        }

        if let hint = documentHint(from: sanitizedTitle) {
            items.append(
                NoxContextEvidenceItem(
                    source: .adapter,
                    kind: .documentHint,
                    value: hint,
                    confidence: 0.7,
                    freshnessSeconds: freshness,
                    explanation: "Document-shaped window title"
                )
            )
        }

        if let hint = mediaHint(from: sanitizedTitle, family: family) {
            items.append(
                NoxContextEvidenceItem(
                    source: .adapter,
                    kind: .mediaHint,
                    value: hint,
                    confidence: 0.75,
                    freshnessSeconds: freshness,
                    explanation: "Passive media shape in title or media app family"
                )
            )
        }

        if let hint = fileTransferHint(from: sanitizedTitle) {
            items.append(
                NoxContextEvidenceItem(
                    source: .adapter,
                    kind: .fileTransferHint,
                    value: hint,
                    confidence: 0.72,
                    freshnessSeconds: freshness,
                    explanation: "Transfer-shaped window title"
                )
            )
        }

        for adapter in adapterEvidence {
            for candidate in adapter.candidates {
                items.append(
                    NoxContextEvidenceItem(
                        source: .adapter,
                        kind: .candidate,
                        value: "\(candidate.contextType.rawValue) \(Int(candidate.confidence * 100))%",
                        confidence: candidate.confidence,
                        freshnessSeconds: freshness,
                        explanation: "Adapter candidate: \(adapter.adapterId)",
                        adapterId: adapter.adapterId
                    )
                )
            }
            for reason in adapter.reasons {
                items.append(
                    NoxContextEvidenceItem(
                        source: .adapter,
                        kind: .dominance,
                        value: reason.detail,
                        confidence: reason.weight,
                        freshnessSeconds: freshness,
                        explanation: "\(adapter.adapterId): \(reason.category)",
                        adapterId: adapter.adapterId
                    )
                )
            }
        }

        if let dominant = resolution.dominant {
            items.append(
                NoxContextEvidenceItem(
                    source: .resolver,
                    kind: .dominance,
                    value: dominant.contextType.rawValue,
                    confidence: resolution.dominanceScore,
                    freshnessSeconds: freshness,
                    explanation: "Dominant context after temporal resolver",
                    adapterId: dominant.sourceAdapterId
                )
            )
        }

        for stale in resolution.staleIgnored {
            items.append(
                NoxContextEvidenceItem(
                    source: .resolver,
                    kind: .dominance,
                    value: "stale: \(stale.contextType.rawValue)",
                    confidence: stale.confidence,
                    freshnessSeconds: freshness,
                    explanation: "Suppressed by sustained context shift",
                    adapterId: stale.sourceAdapterId
                )
            )
        }

        items.append(
            NoxContextEvidenceItem(
                source: .sensitivity,
                kind: .sensitivity,
                value: sensitivity.rawValue,
                confidence: 1,
                freshnessSeconds: freshness,
                explanation: "Sensitivity gate before safe label"
            )
        )

        if safeOutput.detailsRedacted, let reason = safeOutput.redactionReason {
            items.append(
                NoxContextEvidenceItem(
                    source: .sensitivity,
                    kind: .redaction,
                    value: safeOutput.displayLabel,
                    confidence: 1,
                    freshnessSeconds: freshness,
                    sensitivityRisk: sensitivity,
                    explanation: reason
                )
            )
        }

        let observationStatuses = NoxContextObservationMatrix.build(
            snapshot: snapshot,
            capabilities: capabilities,
            domain: domain,
            documentURL: snapshot.documentURL,
            browserFamily: family == .browser,
            mediaFamily: family == .mediaPlayer
        )

        let adapterIds = adapterEvidence.map(\.adapterId)
        let primaryAdapter = resolution.dominant?.sourceAdapterId ?? adapterIds.first ?? "unknown-fallback"

        let resolutionSummary = NoxContextResolutionSummary(
            dominant: resolution.dominant,
            secondary: resolution.secondary,
            staleIgnored: resolution.staleIgnored,
            suppressed: resolution.staleIgnored,
            dominanceScore: resolution.dominanceScore,
            reasons: resolution.reasons,
            supportingSignals: resolution.supportingSignals,
            ignoredSignals: resolution.ignoredSignals
        )

        let appContext = NoxAppContext(
            observedAt: evaluatedAt,
            appName: snapshot.appName,
            bundleId: snapshot.bundleId,
            processId: snapshot.processId,
            windowTitle: sanitizedTitle,
            documentURL: sensitivity == .normal ? snapshot.documentURL : nil,
            browserDomain: sensitivity == .normal ? domain : nil,
            browserPageTitle: family == .browser ? sanitizedTitle : nil,
            documentHint: documentHint(from: sanitizedTitle),
            mediaHint: mediaHint(from: sanitizedTitle, family: family),
            fileTransferHint: fileTransferHint(from: sanitizedTitle),
            interactionShapeSummary: interactionSummary,
            capabilities: capabilityProfile,
            observationStatuses: observationStatuses,
            missingChannels: NoxContextObservationMatrix.missingChannels(from: observationStatuses),
            adapterIds: adapterIds,
            primaryAdapterId: primaryAdapter,
            sensitivity: sensitivity,
            evidenceItems: items,
            resolution: resolutionSummary,
            safeOutput: safeOutput
        )

        return (items, appContext)
    }

    private static func interactionShape(metrics: NoxInteractionMetrics, snapshot: NoxActivitySnapshot) -> String {
        var parts: [String] = []
        if metrics.isWritingHeavy { parts.append("writing-heavy") }
        if metrics.isReadingHeavy { parts.append("reading-heavy") }
        if metrics.isPassive { parts.append("passive") }
        if metrics.isInteractionActive { parts.append("active") }
        if snapshot.isUserIdle { parts.append("user-idle") }
        parts.append(String(format: "typing=%.1f scroll=%.1f", metrics.typingDensity, metrics.scrollIntensity))
        return parts.joined(separator: ", ")
    }

    private static func documentHint(from title: String?) -> String? {
        guard NoxTitleTokenAnalyzer.hasDocumentShapeEvidence(title: title) else { return nil }
        return NoxTitleTokenAnalyzer.primarySegment(from: title) ?? "document"
    }

    private static func mediaHint(from title: String?, family: NoxAppFamily) -> String? {
        if NoxTitleTokenAnalyzer.indicatesPassiveMedia(title: title) {
            return NoxTitleTokenAnalyzer.primarySegment(from: title) ?? "media"
        }
        if family == .mediaPlayer { return "media-player-app" }
        return nil
    }

    private static func fileTransferHint(from title: String?) -> String? {
        guard NoxTitleTokenAnalyzer.hasTransferShapeEvidence(title: title) else { return nil }
        return NoxTitleTokenAnalyzer.primarySegment(from: title) ?? "transfer"
    }
}
