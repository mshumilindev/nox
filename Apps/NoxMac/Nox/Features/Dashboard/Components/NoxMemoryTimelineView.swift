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

struct NoxMemoryTimelineView: View {
  let period: NoxMemoryPeriod
  let sections: [NoxTimelineSection]
  let stats: NoxMemoryDayStats
  let emergence: NoxMemoryEmergence
  let density: Double
  var dayOverview: String?
  var presence: NoxPresenceState = .quiet
  var eraObservation: String?

  private var isEmpty: Bool {
    sections.allSatisfy { $0.items.isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.md) {
      Text("Timeline")
        .noxSectionLabel()

      if let eraObservation, !eraObservation.isEmpty {
        NoxMemoryEraObservationView(line: eraObservation)
      }

      if let dayOverview, !dayOverview.isEmpty {
        Text(dayOverview)
          .font(NoxTypography.body)
          .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom, NoxSpacing.xs)
      }

      if isEmpty {
        emptyState
      } else {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
          ForEach(sections) { section in
            NoxTimelineSectionView(section: section)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var emptyState: some View {
    if period == .today {
      emergenceState
    } else {
      historicalEmptyState
    }
  }

  private var emergenceState: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(emergence.title)
        .font(NoxTypography.body)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))

      if !emergence.detail.isEmpty {
        Text(emergence.detail)
          .noxMetadata()
          .fixedSize(horizontal: false, vertical: true)
      }

      if let windowLine = emergence.observationWindowLine {
        Text(windowLine)
          .font(NoxTypography.caption)
          .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.5))
      }
    }
    .noxSurface(.inset)
  }

  private var historicalEmptyState: some View {
    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
      Text(NoxMemoryPeriodEmptyCopy.title(period: period, stats: stats))
        .font(NoxTypography.body)
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
      Text(NoxMemoryPeriodEmptyCopy.detail(period: period))
        .noxMetadata()
        .fixedSize(horizontal: false, vertical: true)
    }
    .noxSurface(.inset)
  }
}
