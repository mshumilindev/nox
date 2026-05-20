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

struct NoxConnectorPressureCard: View {
    let snapshot: NoxConnectorContinuitySnapshot

    private var lines: [String] {
        var results: [String] = []
        results += snapshot.generalizedSignals.prefix(2).map(\.label)
        results += snapshot.pressureSignals.prefix(2).map(\.label)
        results += snapshot.overloadSignals.prefix(1).map(\.label)
        return Array(results.prefix(4))
    }

    var body: some View {
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: NoxSpacing.sm) {
                Text("Pressure and context")
                    .noxSectionLabel()

                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(NoxTypography.continuityDetail)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(snapshot.explainability.notCollectedSummary)
                    .noxMetadata()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .noxSurface(.soft, padding: NoxSpacing.lg)
        }
    }
}
