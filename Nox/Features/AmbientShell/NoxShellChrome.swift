import SwiftUI

struct NoxShellChrome: View {
  @Environment(AppEnvironment.self) private var environment

  var destination: NoxSemanticDestination
  var compact: Bool = false

  var body: some View {
    HStack(alignment: .center, spacing: NoxSpacing.md) {
      VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
        HStack(spacing: NoxSpacing.sm) {
          NoxIcon(systemName: destination.symbolName, role: .chrome)
          Text(destination.title)
            .font(NoxTypography.destinationTitle)
            .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.94))
            .lineLimit(1)
        }
        if !compact {
          Text(chromeSubtitle)
            .noxMetadata()
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .layoutPriority(1)
      .frame(minWidth: 96, maxWidth: .infinity, alignment: .leading)

      NoxWindowModeControl(
        selection: windowModeBinding,
        compact: compact
      )
      .layoutPriority(0)
      .fixedSize(horizontal: true, vertical: false)
    }
    .padding(.horizontal, compact ? NoxSpacing.md : NoxSpacing.lg)
    .padding(.vertical, NoxTitlebarLayout.chromeVerticalPadding(compact: compact))
    .frame(minHeight: NoxTitlebarLayout.chromeMinHeight(compact: compact), alignment: .center)
    .frame(maxWidth: .infinity)
    .background(
      NoxDesignTokens.ColorRole.surface.opacity(0.48)
        .overlay(
          LinearGradient(
            colors: [
              NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.12),
              .clear
            ],
            startPoint: .top,
            endPoint: .bottom
          )
          .allowsHitTesting(false)
        )
    )
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(NoxDesignTokens.ColorRole.border.opacity(0.24))
        .frame(height: 0.5)
        .allowsHitTesting(false)
    }
  }

  private var chromeSubtitle: String {
    switch destination {
    case .now: "Live ambient context"
    case .presence: "Nearby environments"
    case .threads: "Continuity across time"
    case .memory: "Structured local memory"
    case .patterns: "Semantic arcs and rhythms"
    case .observatory: "Unified continuity signals"
    case .reflections: "Calm local observations"
    case .local: "On-device only"
    case .trust: "Boundaries and control"
    }
  }

  private var windowModeBinding: Binding<NoxWindowMode> {
    Binding(
      get: { environment.preferences.windowMode },
      set: { environment.setWindowMode($0) }
    )
  }
}
