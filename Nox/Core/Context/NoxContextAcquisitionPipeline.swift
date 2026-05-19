import Foundation

struct NoxContextAcquisitionPipeline: Sendable {
    private let registry = NoxContextAdapterRegistry()
    private let scorer = NoxContextEvidenceScorer()
    private let resolver = NoxDominantContextResolver()
    private let appClassifier = NoxAppClassifier()
    private let domainClassifier = NoxDomainClassifier()

    mutating func evaluate(
        snapshot: NoxActivitySnapshot,
        capabilities: NoxCapabilityState,
        metrics: NoxInteractionMetrics,
        stableDurationSeconds: TimeInterval,
        recentSwitchCount: Int,
        resetDominance: Bool = false
    ) -> NoxContextEvidence {
        if resetDominance {
            resolver.reset()
        }

        let capabilityProfile = NoxContextCapabilityProfile.from(capabilities)
        let domain = domainClassifier.domain(
            from: snapshot.windowTitle,
            documentURL: snapshot.documentURL
        )
        let sensitivity = NoxSensitiveContextHandler.sensitivity(
            domain: domain,
            title: snapshot.windowTitle,
            bundleId: snapshot.bundleId
        )
        let sanitizedTitle = NoxSensitiveContextHandler.sanitizedTitle(
            snapshot.windowTitle,
            sensitivity: sensitivity
        )
        let category = appClassifier.classify(
            bundleId: snapshot.bundleId,
            appName: snapshot.appName,
            windowTitle: snapshot.windowTitle
        )
        let family = NoxAppFamilyResolver.resolve(
            bundleId: snapshot.bundleId,
            appName: snapshot.appName,
            category: category
        )

        let input = NoxContextAdapterInput(
            snapshot: snapshot,
            capabilities: capabilityProfile,
            metrics: metrics,
            activityCategory: category,
            sanitizedTitle: sanitizedTitle,
            domain: sensitivity == .normal ? domain : nil,
            stableDurationSeconds: stableDurationSeconds,
            recentSwitchCount: recentSwitchCount,
            sensitivityLevel: sensitivity
        )

        let adapterEvidence = registry.collectEvidence(input: input)
        let ranked = scorer.score(adapterEvidence: adapterEvidence, input: input)
        let adapterReasons = adapterEvidence.flatMap(\.reasons)
        let resolution = resolver.resolve(
            ranked: ranked,
            input: input,
            adapterReasons: adapterReasons,
            at: snapshot.capturedAt
        )

        let safeOutput = NoxSafeDisplayLabelGenerator.make(
            dominant: resolution.dominant,
            sensitivity: sensitivity,
            sanitizedTitle: sanitizedTitle,
            appName: snapshot.appName
        )

        let redactedContent = NoxContextPrivacyGate.redactContentIdentity(
            buildContentIdentity(title: sanitizedTitle, domain: input.domain, family: family),
            sensitivity: sensitivity
        )

        let semantic = NoxSemanticEvidenceBundle(
            candidates: ranked,
            dominant: resolution.dominant,
            secondary: resolution.secondary,
            staleIgnored: resolution.staleIgnored,
            dominanceScore: resolution.dominanceScore,
            sensitivityLevel: sensitivity,
            reasons: resolution.reasons,
            supportingSignals: resolution.supportingSignals,
            ignoredSignals: resolution.ignoredSignals
        )

        let freshness = max(0, Date().timeIntervalSince(snapshot.capturedAt))
        let primaryAdapter = resolution.dominant?.sourceAdapterId
            ?? adapterEvidence.first?.adapterId
            ?? "unknown-fallback"
        let missingPermissions = missingPermissionLabels(capabilityProfile)

        let assembled = NoxContextEvidenceAssembler.assemble(
            snapshot: snapshot,
            capabilities: capabilities,
            capabilityProfile: capabilityProfile,
            sensitivity: sensitivity,
            domain: domain,
            sanitizedTitle: sanitizedTitle,
            family: family,
            metrics: metrics,
            stableDurationSeconds: stableDurationSeconds,
            adapterEvidence: adapterEvidence,
            resolution: resolution,
            safeOutput: safeOutput,
            evaluatedAt: snapshot.capturedAt
        )

        return NoxContextEvidence(
            appIdentity: NoxAppIdentityEvidence(
                appName: snapshot.appName,
                bundleId: snapshot.bundleId,
                processId: snapshot.processId,
                executablePath: nil,
                appFamily: family
            ),
            windowIdentity: NoxWindowIdentityEvidence(
                activeWindowTitle: sanitizedTitle,
                windowRole: nil,
                windowSubrole: nil,
                isFullscreen: false,
                isMinimized: false,
                focusedElementRole: nil
            ),
            contentIdentity: redactedContent,
            activity: NoxActivityEvidence(
                typingDensity: metrics.typingDensity,
                scrollDensity: metrics.scrollIntensity,
                pointerActivityLevel: metrics.mouseDensity,
                idleSeconds: snapshot.idleSeconds,
                stableDurationSeconds: stableDurationSeconds,
                appSwitchCountRecent: recentSwitchCount,
                isInteractionBurst: metrics.isInteractionActive && metrics.typingBurstCount > 2,
                passiveDurationSeconds: metrics.isPassive ? metrics.interactionIdleSeconds : 0,
                isUserIdle: snapshot.isUserIdle,
                recentTransitionSummary: recentSwitchCount > 2 ? "fragmented" : nil
            ),
            capability: NoxCapabilityEvidence(
                acquisitionLevel: capabilityProfile.highestLevel,
                adapterId: primaryAdapter,
                sourceConfidence: resolution.dominanceScore,
                extractionFreshnessSeconds: freshness,
                permissionsRequired: requiredPermissionLabels(),
                permissionsMissing: missingPermissions,
                adapterReliability: adapterEvidence.first { $0.adapterId == primaryAdapter }?.reliability ?? 0.5
            ),
            semantic: semantic,
            safeOutput: safeOutput,
            evaluatedAt: snapshot.capturedAt,
            appContext: assembled.appContext,
            evidenceItems: assembled.items
        )
    }

    private func buildContentIdentity(
        title: String?,
        domain: String?,
        family: NoxAppFamily
    ) -> NoxContentIdentityEvidence {
        let primary = NoxTitleTokenAnalyzer.primarySegment(from: title)
        let secondary = NoxTitleTokenAnalyzer.secondarySegment(from: title)
        return NoxContentIdentityEvidence(
            contextTitle: primary,
            contextSubtitle: secondary,
            documentTitle: NoxTitleTokenAnalyzer.hasDocumentShapeEvidence(title: title) ? primary : nil,
            projectOrWorkspaceTitle: NoxTitleTokenAnalyzer.hasProjectShapeEvidence(title: title) ? primary : nil,
            activeResourceName: primary,
            domain: family == .browser ? domain : nil,
            mediaTitle: NoxTitleTokenAnalyzer.hasMediaShapeEvidence(title: title) ? primary : nil,
            fileName: nil,
            conversationOrChannelName: NoxTitleTokenAnalyzer.hasCommunicationShapeEvidence(title: title)
                ? primary
                : nil
        )
    }

    private func requiredPermissionLabels() -> [String] {
        ["Accessibility", "Screen Recording"]
    }

    private func missingPermissionLabels(_ profile: NoxContextCapabilityProfile) -> [String] {
        var missing: [String] = []
        if !profile.accessibilityGranted { missing.append("Accessibility") }
        if !profile.screenRecordingGranted { missing.append("Screen Recording") }
        return missing
    }
}
