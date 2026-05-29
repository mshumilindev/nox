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
import NoxShrineCore

struct NoxPermissionOnboardingView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xl) {
            Text("What Nox can see")
                .font(NoxTypography.presenceLine)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

            Text("Nox works with partial access. You can add permissions when you want more detail — everything stays on this Mac.")
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            permissionSummary

            NoxCapabilityExplanationView(
                level: .fullSemantic,
                capabilities: environment.capabilities
            )

            NoxLocalFirstBadge()

            HStack(spacing: NoxSpacing.md) {
                Button("Continue") {
                    environment.completeTrustOnboarding()
                    dismiss()
                }
                .font(NoxTypography.actionEmphasis)
                .foregroundStyle(NoxDesignTokens.ColorRole.accent)
                .noxHitTarget(minHeight: 32)
                .buttonStyle(.noxBorderless)

                if !environment.capabilities.accessibilityGranted {
                    Button("Allow window titles") {
                        environment.requestAccessibilityAccess()
                    }
                    .font(NoxTypography.action)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                    .noxHitTarget(minHeight: 32)
                    .buttonStyle(.noxBorderless)
                }
            }
        }
        .padding(NoxSpacing.xl)
        .frame(width: NoxDesignTokens.Window.expandedWidth - 40)
    }

    private var permissionSummary: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            summaryLine(
                granted: true,
                text: "Active apps — always local"
            )
            summaryLine(
                granted: environment.capabilities.accessibilityGranted,
                text: environment.capabilities.accessibilityGranted
                    ? "Window titles — when Accessibility is on"
                    : "Window titles — optional via Accessibility"
            )
            summaryLine(
                granted: false,
                text: "Never: keystrokes, clipboard, screenshots, or cloud upload"
            )
        }
        .noxSurface(.inset, padding: NoxSpacing.md)
    }

    private func summaryLine(granted: Bool, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundStyle(
                    granted
                        ? NoxDesignTokens.ColorRole.presenceActive
                        : NoxDesignTokens.ColorRole.textSecondary.opacity(0.45)
                )
            Text(text)
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
    }
}
