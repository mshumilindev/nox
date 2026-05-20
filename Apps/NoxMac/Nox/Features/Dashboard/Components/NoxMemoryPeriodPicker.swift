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

struct NoxMemoryPeriodPicker: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    HStack(spacing: NoxSpacing.xs) {
      ForEach(NoxMemoryPeriod.allCases) { period in
        Button {
          environment.setMemoryPeriod(period)
        } label: {
          HStack(spacing: NoxSpacing.xxs) {
            NoxIcon(systemName: period.symbolName, role: .inline)
            Text(period.title)
          }
            .font(NoxTypography.sectionLabel)
            .foregroundStyle(
              environment.memoryPeriod == period
                ? NoxDesignTokens.ColorRole.textPrimary
                : NoxDesignTokens.ColorRole.textSecondary
            )
            .padding(.horizontal, NoxSpacing.sm)
            .padding(.vertical, NoxSpacing.xs)
            .background(
              Capsule(style: .continuous)
                .fill(
                  environment.memoryPeriod == period
                    ? NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.secondary)
                    : Color.clear
                )
                .allowsHitTesting(false)
            )
            .noxHitTarget(minHeight: 32)
        }
        .buttonStyle(.noxBorderless(
            hover: .chip,
            isSelected: environment.memoryPeriod == period
        ))
      }
    }
  }
}
