import SwiftUI

struct NoxSystemStateTrustControls: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.lg) {
            Text("System actions boundary")
                .noxSectionLabel()

            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                boundaryLine("Nox may notice local system-state mismatch.")
                boundaryLine("Nox may suggest local actions.")
                boundaryLine("Nox never changes Focus, notifications, or system settings automatically.")
                boundaryLine("Nox-managed display sleep protection only runs after an explicit click.")
                boundaryLine("All action history stays on this Mac.")
            }

            toggleRow(
                title: "System contradiction suggestions",
                detail: "Rare, calm notes when macOS state may not match current activity.",
                isOn: environment.preferences.ambientUtility.systemState.contradictionSuggestionsEnabled,
                set: { environment.setSystemContradictionSuggestionsEnabled($0) }
            )

            toggleRow(
                title: "Display sleep protection suggestions",
                detail: "Offers Nox-managed caffeinate after explicit confirmation only.",
                isOn: environment.preferences.ambientUtility.systemState.caffeinateSuggestionsEnabled,
                set: { environment.setCaffeinateSuggestionsEnabled($0) }
            )

            Button("Clear system action history") {
                environment.clearSystemActionHistory()
            }
            .buttonStyle(.plain)
            .font(NoxTypography.continuityDetail)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
        .noxSurface(.soft, padding: NoxSpacing.lg)
    }

    private func boundaryLine(_ text: String) -> some View {
        Text(text)
            .noxMetadata()
            .fixedSize(horizontal: false, vertical: true)
    }

    private func toggleRow(
        title: String,
        detail: String,
        isOn: Bool,
        set: @escaping (Bool) -> Void
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

            Toggle("", isOn: Binding(get: { isOn }, set: set))
                .labelsHidden()
        }
    }
}
