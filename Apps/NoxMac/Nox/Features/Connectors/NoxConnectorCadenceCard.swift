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

struct NoxConnectorCadenceCard: View {
    let patterns: [NoxCadencePattern]
    let transitions: [NoxTransitionEvent]

    var body: some View {
        if !patterns.isEmpty || !transitions.isEmpty {
            VStack(alignment: .leading, spacing: NoxSpacing.sm) {
                Text("Life rhythm")
                    .noxSectionLabel()

                ForEach(patterns.prefix(3)) { pattern in
                    line(pattern.label, confidence: pattern.confidence)
                }

                ForEach(transitions.prefix(2)) { transition in
                    line(transition.label, confidence: transition.confidence)
                }
            }
            .noxSurface(.soft, padding: NoxSpacing.lg)
        }
    }

    private func line(_ text: String, confidence: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: NoxSpacing.sm) {
            Text(text)
                .font(NoxTypography.continuityDetail)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
            Spacer(minLength: NoxSpacing.sm)
            Text(String(format: "%.0f%%", confidence * 100))
                .noxMetadata()
        }
    }
}
