import SwiftUI

struct NoxConnectorInterventionBanner: View {
    let intervention: NoxAmbientIntervention

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xs) {
            Text(intervention.label)
                .font(NoxTypography.continuityDetail)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
            Text(intervention.detail)
                .noxMetadata()
                .fixedSize(horizontal: false, vertical: true)
        }
        .noxSurface(.inset, padding: NoxSpacing.md)
    }
}
