import SwiftUI
import NoxMemoryCore
import NoxDesignCore

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
