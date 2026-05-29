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

/// Semantic type rhythm — calm ladder, not shouting labels.
enum NoxTypography {
  static let wordmark = Font.system(size: 14, weight: .semibold, design: .rounded)
  static let tagline = Font.system(size: 11, weight: .regular)

  static let surfaceTitle = Font.system(size: 17, weight: .medium, design: .rounded)
  static let surfaceSubtitle = Font.system(size: 12, weight: .regular)
  static let destinationTitle = Font.system(size: 13, weight: .medium)

  static let continuity = Font.system(size: 14, weight: .medium)
  static let continuityDetail = Font.system(size: 12, weight: .regular)

  static let reflection = Font.system(size: 15, weight: .regular)
  static let reflectionSoft = Font.system(size: 13, weight: .regular)

  static let presenceLine = Font.system(size: 11, weight: .medium)
  static let sectionLabel = Font.system(size: 9, weight: .medium)
  static let metadata = Font.system(size: 11, weight: .regular)

  static let body = Font.system(size: 12, weight: .regular)
  static let caption = Font.system(size: 10, weight: .regular)
  static let action = Font.system(size: 12, weight: .regular)
  static let actionEmphasis = Font.system(size: 12, weight: .medium)

  static let controlLabel = Font.system(size: 10, weight: .regular)
  static let railLabel = Font.system(size: 11, weight: .regular)

  static let dashboardTitle = surfaceTitle
  static let dashboardSubtitle = surfaceSubtitle
  static let philosophy = Font.system(size: 11, weight: .regular)
  static let timelineTime = Font.system(size: 10, weight: .regular, design: .monospaced)
  static let timelineStamp = Font.system(size: 10, weight: .regular, design: .monospaced)

  static let sectionTracking: CGFloat = 0.42
}

extension View {
  func noxSectionLabel() -> some View {
    font(NoxTypography.sectionLabel)
      .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.52))
      .textCase(.uppercase)
      .tracking(NoxTypography.sectionTracking)
  }

  func noxMetadata() -> some View {
    font(NoxTypography.metadata)
      .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
  }

  func noxPageTitle() -> some View {
    font(NoxTypography.surfaceTitle)
      .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.94))
  }

  func noxPageSubtitle() -> some View {
    font(NoxTypography.surfaceSubtitle)
      .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.62))
  }
}

struct NoxSurfacePage<Content: View>: View {
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.pageStack) {
      content()
    }
    .frame(maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
  }
}
