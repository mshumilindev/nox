import SwiftUI

struct NoxDashboardHeader: View {
    let presence: NoxPresenceState

    var body: some View {
        HStack(alignment: .top, spacing: NoxSpacing.lg) {
            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                Text("Nox")
                    .font(NoxTypography.dashboardTitle)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)

                Text("Quiet contextual memory")
                    .font(NoxTypography.dashboardSubtitle)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }

            Spacer(minLength: NoxSpacing.md)

            presenceIndicator
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nox. Quiet contextual memory. Presence \(presence.title).")
    }

    private var presenceIndicator: some View {
        HStack(spacing: NoxSpacing.xs) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)

            Text(presence.title)
                .font(NoxTypography.sectionLabel)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
        .padding(.horizontal, NoxSpacing.sm)
        .padding(.vertical, NoxSpacing.xs)
        .background(
            Capsule(style: .continuous)
                .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.secondary))
        )
    }

    private var indicatorColor: Color {
        switch presence {
        case .limited, .quiet, .idle, .resting:
            NoxDesignTokens.ColorRole.presenceMuted
        case .active, .distracted:
            NoxDesignTokens.ColorRole.presenceActive
        case .focused, .flow:
            NoxDesignTokens.ColorRole.accent
        }
    }
}

#Preview {
    NoxDashboardHeader(presence: .quiet)
        .padding()
        .frame(width: NoxDesignTokens.Window.width)
}
