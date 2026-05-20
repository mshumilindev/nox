import SwiftUI

struct NoxSemanticNavigationRail: View {
  @Environment(AppEnvironment.self) private var environment

  private let primary: [NoxSemanticDestination] = [.now, .threads, .memory, .observatory]
  private let reflective: [NoxSemanticDestination] = [.patterns, .reflections]
  private let system: [NoxSemanticDestination] = [.local, .trust]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: NoxSpacing.sm) {
        Image("NoxTriskelionMark")
          .resizable()
          .renderingMode(.template)
          .scaledToFit()
          .frame(width: 16, height: 16)
          .foregroundStyle(NoxDesignTokens.ColorRole.accent)
          .accessibilityHidden(true)

        Text("Nox")
          .font(NoxTypography.wordmark)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
      }
        .padding(.horizontal, NoxSpacing.md)
        .padding(.top, NoxTitlebarLayout.chromeVerticalPadding(compact: false))
        .padding(.bottom, NoxSpacing.lg)

      navGroup(primary)
      railDivider
      navGroup(reflective)
      railDivider
      navGroup(system)

      Spacer(minLength: NoxSpacing.md)
    }
    .frame(width: NoxMaterials.railWidth)
    .background(NoxDesignTokens.ColorRole.rail)
    .overlay(alignment: .trailing) {
      Rectangle()
        .fill(NoxDesignTokens.ColorRole.border.opacity(0.2))
        .frame(width: 0.5)
        .allowsHitTesting(false)
    }
  }

  private func navGroup(_ destinations: [NoxSemanticDestination]) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(destinations) { destination in
        navRow(destination)
      }
    }
    .padding(.vertical, NoxSpacing.xxs)
  }

  private var railDivider: some View {
    Rectangle()
      .fill(NoxDesignTokens.ColorRole.border.opacity(0.18))
      .frame(height: 0.5)
      .padding(.horizontal, NoxSpacing.md)
      .padding(.vertical, NoxSpacing.xs)
      .allowsHitTesting(false)
  }

  private func navRow(_ destination: NoxSemanticDestination) -> some View {
    let selected = environment.preferences.navigationDestination == destination
    return Button {
      environment.setNavigationDestination(destination)
    } label: {
      HStack(spacing: NoxSpacing.sm) {
        NoxIcon(
          systemName: destination.symbolName,
          role: .inline,
          emphasized: selected
        )
        Text(destination.title)
          .font(selected ? Font.system(size: 11, weight: .medium) : NoxTypography.railLabel)
          .foregroundStyle(
            selected
              ? NoxDesignTokens.ColorRole.textPrimary.opacity(0.92)
              : NoxDesignTokens.ColorRole.textSecondary.opacity(0.68)
          )
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      .padding(.leading, NoxSpacing.md)
      .padding(.trailing, NoxSpacing.sm)
      .padding(.vertical, 7)
      .background {
        if selected {
          HStack(spacing: 0) {
            Rectangle()
              .fill(NoxDesignTokens.ColorRole.accent.opacity(0.55))
              .frame(width: 2)
            Spacer(minLength: 0)
          }
          .allowsHitTesting(false)
        }
      }
      .noxHitTarget(minHeight: 36)
    }
    .buttonStyle(.noxBorderless(hover: .row, isSelected: selected))
  }

}
