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

struct NoxSystemStateTrustControls: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            Text("System suggestions")
                .noxSectionLabel()

            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                boundaryLine("Nox may notice when macOS state does not match what you are doing.")
                boundaryLine("Suggestions stay local. Nothing changes without your click.")
            }

            NoxSettingsToggleRow(
                title: "State mismatch notes",
                detail: "Rare notes when Focus, battery, or similar may not match activity.",
                isOn: Binding(
                    get: { environment.preferences.ambientUtility.systemState.contradictionSuggestionsEnabled },
                    set: { environment.setSystemContradictionSuggestionsEnabled($0) }
                )
            )

            NoxSettingsToggleRow(
                title: "Display sleep suggestions",
                detail: "Offers to keep the display awake only after you confirm.",
                isOn: Binding(
                    get: { environment.preferences.ambientUtility.systemState.caffeinateSuggestionsEnabled },
                    set: { environment.setCaffeinateSuggestionsEnabled($0) }
                )
            )

            Button("Clear suggestion history") {
                environment.clearSystemActionHistory()
            }
            .buttonStyle(.plain)
            .font(NoxTypography.caption)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
        .noxSurface(.soft, padding: NoxSpacing.lg)
    }

    private func boundaryLine(_ text: String) -> some View {
        Text(text)
            .noxMetadata()
            .fixedSize(horizontal: false, vertical: true)
    }
}
