import SwiftUI

struct NoxMemoryControlCenter: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.lg) {
      Text("Memory controls")
        .noxSectionLabel()

      VStack(alignment: .leading, spacing: 0) {
        controlToggle(
          title: "Pause observation",
          detail: "Stops new timeline activity until resumed.",
          isOn: environment.preferences.pauseState.observationPaused
        ) {
          environment.setObservationPaused(!$0)
        }

        controlDivider

        controlToggle(
          title: "Pause semantic memory",
          detail: "Context may still appear — memory formation pauses.",
          isOn: environment.preferences.pauseState.semanticMemoryPaused
        ) {
          environment.setSemanticMemoryPaused(!$0)
        }

        controlDivider

        quietModeRow
      }

      VStack(alignment: .leading, spacing: NoxSpacing.sm) {
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
      .padding(.vertical, NoxSpacing.sm)
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
      .allowsHitTesting(false)

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
  }

  private var quietBinding: Binding<NoxQuietMode> {
    Binding(
      get: { environment.preferences.pauseState.quietMode },
      set: { environment.setQuietMode($0) }
    )
  }

  private func controlToggle(
    title: String,
    detail: String,
    isOn: Bool,
    onChange: @escaping @MainActor (Bool) -> Void
  ) -> some View {
    HStack(alignment: .top, spacing: NoxSpacing.md) {
      VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
        Text(title)
          .font(NoxTypography.continuityDetail)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
        Text(detail)
          .noxMetadata()
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .allowsHitTesting(false)

      Toggle("", isOn: Binding(get: { isOn }, set: onChange))
        .labelsHidden()
        .toggleStyle(.switch)
        .padding(.top, 1)
        .noxInteractiveChrome(.row)
    }
    .padding(.vertical, NoxSpacing.sm)
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
