import SwiftUI
import NoxDesignCore

/// Menu bar block: one row button — Toggle Orby (left) + mood-matched preview (right).
struct OrbyMenuBarSectionView: View {
  @Environment(\.noxMenuBarDismiss) private var closeMenuBar
  @Environment(\.dismiss) private var dismiss
  @Environment(AppEnvironment.self) private var environment

  @State private var plateHovered = false

  private var shrine: ShrineSurfaceController { NoxAppRuntime.shrine }

  private var resolvedMood: OrbyMood {
    shrine.baseMood(for: environment)
  }

  private var moodInputs: ShrineMoodInputs {
    OrbyMoodResolver.inputs(
      from: environment,
      soundsMuted: shrine.soundsMuted,
      recentDismissCount: shrine.recentMiniDismissCount
    )
  }

  private var menuIntensity: OrbyEmotionIntensity {
    OrbyEmotionIntensityResolver.resolve(mood: resolvedMood, input: moodInputs)
  }

  private var menuEmotion: OrbyEmotionAppearance {
    OrbyEmotionCompositor.compose(
      mood: resolvedMood,
      intensity: menuIntensity,
      phase: .awake,
      eyelidClosure: 0,
      isExcited: false
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text("ORBY")
        .font(NoxTypography.sectionLabel)
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        .tracking(0.6)

      Button {
        closeMenuBarPanel()
        shrine.toggleMini()
      } label: {
        HStack(alignment: .center, spacing: NoxSpacing.sm) {
          Text("Toggle Orby")
            .font(NoxTypography.action)
            .frame(maxWidth: .infinity, alignment: .leading)

          OrbyMenuBarMarkView(
            mood: resolvedMood,
            intensity: menuIntensity,
            emotion: menuEmotion,
            moodTitle: resolvedMood.displayTitle
          )
            .accessibilityHidden(true)
        }
        .padding(NoxSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(plateBackground)
        .contentShape(
          RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
        )
        .onContinuousHover { phase in
          switch phase {
          case .active:
            plateHovered = true
          case .ended:
            plateHovered = false
          }
        }
        .animation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade), value: plateHovered)
      }
      .buttonStyle(OrbyMenuBarPlateButtonStyle())
      .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
      .accessibilityLabel(toggleAccessibilityLabel)
      .accessibilityHint(toggleAccessibilityHint)
    }
  }

  private var toggleAccessibilityLabel: String {
    shrine.isMiniVisible ? "Hide Orby" : "Show Orby"
  }

  private var toggleAccessibilityHint: String {
    if shrine.isMiniVisible {
      return "Hides the floating Orby orb."
    }
    return "Shows Orby at the default bottom-right position."
  }

  private func closeMenuBarPanel() {
    closeMenuBar?()
    dismiss()
  }

  private var plateBackground: some View {
    let shape = RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
    return ZStack {
      shape.fill(NoxDesignTokens.ColorRole.surfaceElevated)
      if plateHovered {
        shape.fill(Color.white.opacity(0.07))
        shape.strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.26), lineWidth: 0.5)
      }
    }
  }
}

/// Press feedback only — hover is drawn on the elevated plate background.
private struct OrbyMenuBarPlateButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.82 : 1)
      .animation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade), value: configuration.isPressed)
  }
}

#Preview {
  OrbyMenuBarSectionView()
    .environment(AppEnvironment())
    .padding()
    .frame(width: NoxSpacing.menuBarWidth)
    .preferredColorScheme(.dark)
}
