import SwiftUI

struct NoxConnectorTrustControls: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            Text("Connectors")
                .noxSectionLabel()

            Text("Generalized timing only — never inbox automation.")
                .noxMetadata()
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 0) {
                NoxSettingsToggleRow(
                    title: "Calendar",
                    detail: "Meeting density and timing. Titles are not stored.",
                    isOn: Binding(
                        get: { environment.preferences.connectors.calendarEnabled },
                        set: { environment.setCalendarConnectorEnabled($0) }
                    )
                )

                divider

                NoxSettingsToggleRow(
                    title: "Communication load",
                    detail: "App cadence from local metadata — not message bodies.",
                    isOn: Binding(
                        get: { environment.preferences.connectors.communicationPressureEnabled },
                        set: { environment.setCommunicationPressureEnabled($0) }
                    )
                )

                divider

                NoxSettingsToggleRow(
                    title: "Pause connector signals",
                    detail: "Mac awareness continues; calendar and message cadence pause.",
                    isOn: Binding(
                        get: { environment.preferences.connectors.continuityEnrichmentPaused },
                        set: { environment.setContinuityEnrichmentPaused($0) }
                    )
                )
            }

            HStack(spacing: NoxSpacing.md) {
                Button("Request calendar access") {
                    Task { await environment.requestCalendarAccess() }
                }
                .font(NoxTypography.caption)
                .buttonStyle(.noxBorderless)

                Button("Clear connector data") {
                    Task { await environment.clearConnectorContinuity() }
                }
                .font(NoxTypography.caption)
                .buttonStyle(.noxBorderless)
            }
        }
        .noxSurface(.soft, padding: NoxSpacing.lg)
    }

    private var divider: some View {
        Rectangle()
            .fill(NoxDesignTokens.ColorRole.border.opacity(0.12))
            .frame(height: 0.5)
            .padding(.horizontal, NoxSpacing.xs)
    }
}
