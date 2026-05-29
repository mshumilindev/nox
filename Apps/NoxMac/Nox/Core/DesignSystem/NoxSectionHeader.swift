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

struct NoxSectionHeader: View {
    let title: String
    var symbol: String?
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
            HStack(spacing: NoxSpacing.xs) {
                if let symbol {
                    NoxIcon(systemName: symbol, role: .section)
                }
                Text(title)
                    .noxSectionLabel()
            }
            if let subtitle {
                Text(subtitle)
                    .noxMetadata()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct NoxPageIntro: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text(title)
                .noxPageTitle()
            Text(subtitle)
                .noxPageSubtitle()
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
