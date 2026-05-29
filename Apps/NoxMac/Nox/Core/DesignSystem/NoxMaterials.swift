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

/// Three surface levels — avoid “everything is a mega card”.
enum NoxSurfaceTier: Sendable {
  /// Rare hero: reflections, morning continuity.
  case major
  /// Context entities: arcs, threads, presence.
  case standard
  /// Metadata, controls, grouped lists — almost borderless.
  case soft
  /// Empty / waiting states.
  case inset
}

enum NoxMaterials {
  static let railWidth: CGFloat = 132
  /// Deep Reflection — full destination titles without truncation.
  static let deepReflectionRailWidth: CGFloat = 148
  static let contentPadding: CGFloat = NoxSpacing.lg
  static let readableWidth: CGFloat = NoxSurfaceLayout.contentMaxReadable
  static let clusterSpacing: CGFloat = NoxSpacing.md
  static let cardPadding: CGFloat = NoxSpacing.cardInset
  static let cardPaddingLoose: CGFloat = NoxSpacing.cardInsetLoose

  static func fill(for tier: NoxSurfaceTier) -> Color {
    switch tier {
    case .major:
      NoxDesignTokens.ColorRole.reflectionFill.opacity(0.74)
    case .standard:
      NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.48)
    case .soft:
      NoxDesignTokens.ColorRole.surface.opacity(0.18)
    case .inset:
      NoxDesignTokens.ColorRole.canvas.opacity(0.42)
    }
  }

  static func stroke(for tier: NoxSurfaceTier) -> Color {
    switch tier {
    case .major:
      NoxDesignTokens.ColorRole.reflectionStroke.opacity(0.28)
    case .standard:
      NoxDesignTokens.ColorRole.border.opacity(0.16)
    case .soft, .inset:
      NoxDesignTokens.ColorRole.border.opacity(0.10)
    }
  }

  static func radius(for tier: NoxSurfaceTier) -> CGFloat {
    switch tier {
    case .major: NoxDesignTokens.Radius.md
    case .standard, .inset: NoxDesignTokens.Radius.sm
    case .soft: NoxDesignTokens.Radius.sm
    }
  }

  static func padding(for tier: NoxSurfaceTier) -> CGFloat {
    switch tier {
    case .major: cardPaddingLoose
    case .standard: cardPadding
    case .soft: NoxSpacing.sm
    case .inset: cardPaddingLoose
    }
  }
}

struct NoxSurfaceModifier: ViewModifier {
  let tier: NoxSurfaceTier
  var padding: CGFloat?

  func body(content: Content) -> some View {
    let pad = padding ?? NoxMaterials.padding(for: tier)
  content
      .padding(pad)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        if tier == .soft {
          RoundedRectangle(cornerRadius: NoxMaterials.radius(for: tier), style: .continuous)
            .fill(NoxMaterials.fill(for: tier))
        } else {
          RoundedRectangle(cornerRadius: NoxMaterials.radius(for: tier), style: .continuous)
            .fill(NoxMaterials.fill(for: tier))
            .overlay(
              RoundedRectangle(cornerRadius: NoxMaterials.radius(for: tier), style: .continuous)
                .strokeBorder(NoxMaterials.stroke(for: tier), lineWidth: tier == .major ? 0.5 : 0.5)
            )
        }
      }
  }
}

extension View {
  func noxSurface(_ tier: NoxSurfaceTier = .standard, padding: CGFloat? = nil) -> some View {
    modifier(NoxSurfaceModifier(tier: tier, padding: padding))
  }

  /// Grouped content without a mega wrapper.
  func noxGroup(spacing: CGFloat = NoxSpacing.md, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: spacing) {
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  func noxReadableWidth() -> some View {
    frame(maxWidth: NoxMaterials.readableWidth, alignment: .leading)
  }

  @available(*, deprecated, message: "Use noxGroup — avoids mega rectangles")
  func noxCluster(@ViewBuilder content: () -> some View) -> some View {
    noxGroup(spacing: NoxSpacing.md, content: content)
  }
}
