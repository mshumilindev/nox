import SwiftUI

struct NoxConnectorInterventionBanner: View {
    @Environment(AppEnvironment.self) private var environment
    let intervention: NoxAmbientIntervention

    @State private var showExplainability = false

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text(intervention.label)
                .font(NoxTypography.continuityDetail)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
            Text(intervention.detail)
                .noxMetadata()
                .fixedSize(horizontal: false, vertical: true)

            if intervention.kind == .systemState {
                if let assurance = intervention.assuranceLine {
                    Text(assurance)
                        .noxMetadata()
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.85))
                }

                if !intervention.actions.isEmpty {
                    actionButtons
                }

                if let explainability = intervention.explainabilityDetail {
                    Button(showExplainability ? "Hide why this appeared" : "Why this appeared") {
                        showExplainability.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(NoxTypography.continuityDetail)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)

                    if showExplainability {
                        Text(explainability)
                            .noxMetadata()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .noxSurface(.inset, padding: NoxSpacing.md)
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            ForEach(intervention.actions) { action in
                Button {
                    environment.performSystemInterventionAction(action)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.title)
                            .font(NoxTypography.continuityDetail)
                        if !action.detail.isEmpty {
                            Text(action.detail)
                                .noxMetadata()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
            }
        }
        .padding(.top, NoxSpacing.xxs)
    }
}
