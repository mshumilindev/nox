import SwiftUI

struct NoxPermissionOnboardingView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xl) {
            Text("How Nox sees context")
                .font(NoxTypography.presenceLine)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

            Text("Nox stays useful without every permission. You choose how much local context to share.")
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            NoxCapabilityExplanationView(
                level: .fullSemantic,
                capabilities: environment.capabilities
            )

            NoxLocalFirstBadge()

            HStack(spacing: NoxSpacing.md) {
                Button("Continue with current access") {
                    environment.completeTrustOnboarding()
                    dismiss()
                }
                .font(NoxTypography.actionEmphasis)
                .foregroundStyle(NoxDesignTokens.ColorRole.accent)
                .noxHitTarget(minHeight: 32)
                .buttonStyle(.noxBorderless)

                Button("Open Accessibility") {
                    environment.requestAccessibilityAccess()
                }
                .font(NoxTypography.action)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .noxHitTarget(minHeight: 32)
                .buttonStyle(.noxBorderless)
            }
        }
        .padding(NoxSpacing.xl)
        .frame(width: NoxDesignTokens.Window.expandedWidth - 40)
    }
}
