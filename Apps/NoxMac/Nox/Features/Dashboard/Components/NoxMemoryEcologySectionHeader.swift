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

enum NoxMemoryEcologyLayerVisualWeight {
    case galaxy
    case orbit
    case deepSpace

    var titleOpacity: Double {
        switch self {
        case .galaxy: 0.95
        case .orbit: 0.82
        case .deepSpace: 0.68
        }
    }

    var subtitleOpacity: Double {
        switch self {
        case .galaxy: 0.78
        case .orbit: 0.62
        case .deepSpace: 0.52
        }
    }

    var contentOpacity: Double {
        switch self {
        case .galaxy: 1.0
        case .orbit: 0.9
        case .deepSpace: 0.78
        }
    }

    var layer: NoxMemoryEcologyPrimaryLayer {
        switch self {
        case .galaxy: .galaxy
        case .orbit: .orbit
        case .deepSpace: .deepSpace
        }
    }
}

struct NoxMemoryEcologySectionHeader: View {
    let title: String
    let subtitle: String
    let weight: NoxMemoryEcologyLayerVisualWeight
    var isPrimaryLayer: Bool = false

    private var effectiveWeight: NoxMemoryEcologyLayerVisualWeight {
        isPrimaryLayer ? .galaxy : weight
    }

    var body: some View {
        HStack(alignment: .top, spacing: NoxSpacing.sm) {
            NoxIcon(
                systemName: NoxMemoryEcologyIcons.symbol(for: effectiveWeight.layer),
                role: .section,
                tint: NoxDesignTokens.ColorRole.textSecondary.opacity(0.7)
            )
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(effectiveWeight.titleOpacity))
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(effectiveWeight.subtitleOpacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
