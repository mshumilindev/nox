import SwiftUI

struct NoxConnectorTrustControls: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            Text("Connector awareness")
                .noxSectionLabel()

            Text("Used only for generalized continuity — never inbox automation.")
                .noxMetadata()
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 0) {
                connectorToggle(
                    title: "Calendar context",
                    detail: "Read-only timing and density. Titles are not stored.",
                    isOn: environment.preferences.connectors.calendarEnabled
                ) { environment.setCalendarConnectorEnabled($0) }

                divider

                connectorToggle(
                    title: "Communication pressure",
                    detail: "Cadence from local app metadata — not message bodies.",
                    isOn: environment.preferences.connectors.communicationPressureEnabled
                ) { environment.setCommunicationPressureEnabled($0) }

                divider

                connectorToggle(
                    title: "Pause continuity enrichment",
                    detail: "Mac awareness may continue; connector signals pause.",
                    isOn: environment.preferences.connectors.continuityEnrichmentPaused
                ) { environment.setContinuityEnrichmentPaused($0) }
            }

            HStack(spacing: NoxSpacing.md) {
                Button("Request calendar access") {
                    Task { await environment.requestCalendarAccess() }
                }
                .font(NoxTypography.caption)
                .buttonStyle(.noxBorderless)

                Button("Clear connector continuity") {
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
            .padding(.vertical, NoxSpacing.sm)
    }

    private func connectorToggle(
        title: String,
        detail: String,
        isOn: Bool,
        onChange: @escaping @MainActor (Bool) -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: NoxSpacing.md) {
            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text(title)
                    .font(NoxTypography.continuityDetail)
                Text(detail)
                    .noxMetadata()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)

            Toggle("", isOn: Binding(get: { isOn }, set: onChange))
                .labelsHidden()
                .noxInteractiveChrome(.row)
        }
        .padding(.vertical, NoxSpacing.sm)
    }
}
