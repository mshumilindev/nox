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

struct NoxCapabilityExplanationView: View {
    let level: NoxAwarenessLevel
    let capabilities: NoxCapabilityState

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            ForEach(NoxAwarenessLevel.allCases.filter { $0 <= level }, id: \.self) { tier in
                tierRow(tier, unlocked: tier <= level)
            }

            if !capabilities.accessibilityGranted {
                Text("Accessibility adds window titles. Nothing leaves this Mac.")
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }
        }
    }

    private func tierRow(_ tier: NoxAwarenessLevel, unlocked: Bool) -> some View {
        HStack(alignment: .top, spacing: NoxSpacing.sm) {
            Image(systemName: unlocked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(
                    unlocked
                        ? NoxDesignTokens.ColorRole.presenceActive
                        : NoxDesignTokens.ColorRole.textSecondary.opacity(0.5)
                )
            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text(tier.title)
                    .font(NoxTypography.actionEmphasis)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                Text(tier.exampleLine)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }
        }
    }
}
