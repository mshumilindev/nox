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

/// Quiet mode switch — integrated into chrome, not a glossy pill.
struct NoxWindowModeControl: View {
  @Binding var selection: NoxWindowMode
  var compact: Bool = false

  var body: some View {
    HStack(spacing: 0) {
      ForEach(NoxWindowMode.allCases) { mode in
        modeChip(mode)
        if mode != NoxWindowMode.allCases.last {
          Divider()
            .frame(height: 14)
            .opacity(0.25)
        }
      }
    }
    .padding(.horizontal, 2)
    .padding(.vertical, 2)
  }

  private func modeChip(_ mode: NoxWindowMode) -> some View {
    let selected = selection == mode
    return Button {
      selection = mode
    } label: {
      Text(compact ? mode.compactTitle : mode.title)
        .font(NoxTypography.controlLabel)
        .foregroundStyle(
          selected
            ? NoxDesignTokens.ColorRole.textPrimary.opacity(0.88)
            : NoxDesignTokens.ColorRole.textSecondary.opacity(0.5)
        )
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
          if selected {
            Rectangle()
              .fill(NoxDesignTokens.ColorRole.accent.opacity(0.45))
              .frame(height: 1)
              .padding(.horizontal, 4)
          }
        }
    }
    .buttonStyle(.noxBorderless(hover: .chip, isSelected: selected))
  }
}

extension NoxWindowMode {
  var compactTitle: String {
    switch self {
    case .compact: "Compact"
    case .expanded: "Expanded"
    case .deepReflection: "Deep"
    }
  }
}
