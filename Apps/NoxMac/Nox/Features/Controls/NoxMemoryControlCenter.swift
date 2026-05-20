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

struct NoxMemoryControlCenter: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.lg) {
      Text("Memory")
        .noxSectionLabel()

      VStack(alignment: .leading, spacing: 0) {
        NoxSettingsToggleRow(
          title: "Pause observation",
          detail: "Stops recording new timeline activity.",
          isOn: Binding(
            get: { environment.preferences.pauseState.observationPaused },
            set: { environment.setObservationPaused($0) }
          )
        )

        controlDivider

        NoxSettingsToggleRow(
          title: "Pause memory formation",
          detail: "Live context may still appear; new memory spans pause.",
          isOn: Binding(
            get: { environment.preferences.pauseState.semanticMemoryPaused },
            set: { environment.setSemanticMemoryPaused($0) }
          )
        )

        controlDivider

        quietModeRow
      }

      HStack(spacing: NoxSpacing.md) {
        actionButton("Clear recent activity") {
          Task { await environment.clearRecentMemory() }
        }
        actionButton("Clear stored patterns") {
          Task { await environment.clearSemanticContinuity() }
        }
      }
      .padding(.top, NoxSpacing.xs)
    }
    .noxSurface(.soft, padding: NoxSpacing.lg)
  }

  private var controlDivider: some View {
    Rectangle()
      .fill(NoxDesignTokens.ColorRole.border.opacity(0.12))
      .frame(height: 0.5)
      .padding(.horizontal, NoxSpacing.xs)
  }

  private var quietModeRow: some View {
    HStack(alignment: .top, spacing: NoxSpacing.md) {
      VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
        Text("Quiet mode")
          .font(NoxTypography.continuityDetail)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
        Text(environment.preferences.pauseState.quietMode.detail)
          .noxMetadata()
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Picker("", selection: quietBinding) {
        ForEach(NoxQuietMode.allCases, id: \.self) { mode in
          Text(mode.title).tag(mode)
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .frame(width: 132, alignment: .trailing)
      .noxInteractiveChrome(.chip)
    }
    .padding(.vertical, NoxSpacing.sm)
    .padding(.horizontal, NoxSpacing.xs)
  }

  private var quietBinding: Binding<NoxQuietMode> {
    Binding(
      get: { environment.preferences.pauseState.quietMode },
      set: { environment.setQuietMode($0) }
    )
  }

  private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
      .font(NoxTypography.caption)
      .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.72))
      .underline(color: NoxDesignTokens.ColorRole.border.opacity(0.35))
      .noxHitTarget(minHeight: 28)
      .buttonStyle(.noxBorderless)
  }
}
