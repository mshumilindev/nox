import SwiftUI
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

#if DEBUG

/// Developer-only context explainability — not part of normal user UI.
struct NoxContextExplainabilityView: View {
    let snapshot: NoxContextDebugSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            header
            if let snapshot {
                content(snapshot)
            } else {
                Text("Waiting for first context evaluation…")
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }
        }
        .padding(NoxSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .stroke(NoxDesignTokens.ColorRole.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text("Context evidence (dev)")
                .font(NoxTypography.sectionLabel)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            Text(NoxDevRuntimeIdentity.launchContextSummary)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.85))
            Text("Runtime: \(NoxDevRuntimeIdentity.permissionTargetSummary)")
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.85))
        }
    }

    @ViewBuilder
    private func content(_ snapshot: NoxContextDebugSnapshot) -> some View {
        Group {
            row("App", "\(snapshot.activeApp) · \(snapshot.bundleId)")
            row("PID", snapshot.processId)
            row("Window", snapshot.windowTitle ?? "—")
            row("URL", snapshot.browserURL ?? "—")
            row("Domain", snapshot.browserDomain ?? "—")
            row("Adapters", snapshot.adaptersInvoked.joined(separator: ", "))
            row("Primary adapter", snapshot.adapterUsed)
            row("Acquisition", snapshot.acquisitionLevel)
            row("Freshness", String(format: "%.1fs", snapshot.freshnessSeconds))
            row("Interaction", snapshot.interactionShape)
            row("Dominant", snapshot.dominantContext ?? "—")
            row("Secondary", snapshot.secondaryContexts.joined(separator: ", "))
            row("Stale", snapshot.staleIgnored.joined(separator: ", "))
            row("Sensitivity", snapshot.sensitivityDecision)
            row("Redaction", snapshot.redactionReason ?? "—")
            row("Safe label", snapshot.safeDisplayLabel)
        }

        if !snapshot.observationStatuses.isEmpty {
            section("Capabilities") {
                ForEach(snapshot.observationStatuses, id: \.self) { line in
                    Text(line)
                        .font(NoxTypography.caption)
                        .foregroundStyle(line.hasPrefix("✓")
                            ? NoxDesignTokens.ColorRole.textPrimary
                            : NoxDesignTokens.ColorRole.textSecondary)
                }
            }
        }

        if !snapshot.evidenceItems.isEmpty {
            section("Evidence") {
                ForEach(Array(snapshot.evidenceItems.prefix(12).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if snapshot.evidenceItems.count > 12 {
                    Text("+\(snapshot.evidenceItems.count - 12) more")
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.7))
                }
            }
        }

        if !snapshot.candidates.isEmpty {
            section("Candidates") {
                ForEach(snapshot.candidates, id: \.self) { line in
                    Text(line)
                        .font(NoxTypography.caption)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: NoxSpacing.sm) {
            Text(label)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text(title)
                .font(NoxTypography.caption.weight(.semibold))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            content()
        }
    }
}
#endif
