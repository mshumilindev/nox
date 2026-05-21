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

struct NoxSemanticNavigationRail: View {
  @Environment(AppEnvironment.self) private var environment

  private var primary: [NoxSemanticDestination] {
    [.now, .presence, .threads, .memory, .observatory]
      .filter { environment.showsDestinationInNavigation($0) }
  }
  private let reflective: [NoxSemanticDestination] = [.patterns, .reflections]
  private let system: [NoxSemanticDestination] = [.local, .trust]

  private var railWidth: CGFloat {
    environment.preferences.windowMode == .deepReflection
      ? NoxMaterials.deepReflectionRailWidth
      : NoxMaterials.railWidth
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: NoxSpacing.sm) {
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
    .frame(width: railWidth)
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
    let isEcology = destination == .memory
    return Button {
      environment.setNavigationDestination(destination)
    } label: {
      HStack(alignment: .center, spacing: NoxSpacing.sm) {
        NoxIcon(
          systemName: environment.navigationSymbolName(for: destination),
          role: .rail,
          emphasized: selected,
          tint: isEcology && !selected
            ? NoxDesignTokens.ColorRole.textSecondary.opacity(0.55)
            : nil
        )

        NoxSemanticNavigationLabel(
          title: environment.navigationTitle(for: destination),
          secondaryHint: environment.navigationSecondaryHint(for: destination),
          isEcologyMode: isEcology,
          selected: selected
        )
        Spacer(minLength: 0)
      }
      .padding(.leading, NoxSpacing.md)
      .padding(.trailing, NoxSpacing.sm)
      .padding(.vertical, isEcology ? 8 : 7)
      .background {
        if selected {
          HStack(spacing: 0) {
            Rectangle()
              .fill(
                NoxDesignTokens.ColorRole.accent.opacity(isEcology ? 0.42 : 0.55)
              )
              .frame(width: 2)
            Spacer(minLength: 0)
          }
          .allowsHitTesting(false)
        }
      }
      .noxHitTarget(minHeight: isEcology ? 44 : 36)
    }
    .buttonStyle(.noxBorderless(hover: .row, isSelected: selected))
  }

}
