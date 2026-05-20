import SwiftUI

struct NoxDashboardHeader: View {
    let presence: NoxPresenceState

    var body: some View {
        HStack(alignment: .center, spacing: NoxSpacing.lg) {
            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text("Ambient layer")
                    .noxPageTitle()
                Text("Local activity memory")
                    .noxPageSubtitle()
            }

            Spacer(minLength: NoxSpacing.md)

            presenceIndicator
        }
    }

    private var presenceIndicator: some View {
        HStack(spacing: NoxSpacing.xs) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 5, height: 5)
            Text(presence.title)
                .font(NoxTypography.metadata)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.78))
        }
        .padding(.horizontal, NoxSpacing.sm)
        .padding(.vertical, NoxSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
                .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.28), lineWidth: 0.5)
        )
    }

    private var indicatorColor: Color {
        switch presence {
        case .limited, .quiet, .idle, .resting:
            NoxDesignTokens.ColorRole.presenceMuted
        case .active, .distracted:
            NoxDesignTokens.ColorRole.presenceActive
        case .focused, .flow:
            NoxDesignTokens.ColorRole.accent.opacity(0.85)
        }
    }
}
