import SwiftUI

struct NoxSystemStatusView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            sectionHeader("LOCAL")

            VStack(alignment: .leading, spacing: NoxSpacing.md) {
                statusRow(label: "Menu bar", value: "Active", tone: .active)
                statusRow(label: "Local mode", value: "On this Mac", tone: .active)

                Divider().opacity(0.35)

                ForEach(environment.capabilityRows) { row in
                    statusRow(label: row.feature, value: row.status, tone: row.tone)
                }

                if !environment.capabilities.windowAwarenessAvailable {
                    permissionActions
                }
            }
            .padding(NoxSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
    }

    private var permissionActions: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text("Accessibility allows window titles and deeper context. Everything stays on this Mac.")
                .font(NoxTypography.caption)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: NoxSpacing.sm) {
                Button("Open System Settings") {
                    environment.openAccessibilitySettings()
                }
                .buttonStyle(.plain)
                .font(NoxTypography.actionEmphasis)
                .foregroundStyle(NoxDesignTokens.ColorRole.accent)

                Button("Retry") {
                    environment.requestAccessibilityAccess()
                    environment.refreshPermissions()
                }
                .buttonStyle(.plain)
                .font(NoxTypography.action)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }
        }
        .padding(.top, NoxSpacing.xs)
    }

    private func statusRow(label: String, value: String, tone: NoxCapabilityTone) -> some View {
        HStack {
            Text(label)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)

            Spacer()

            Text(value)
                .font(NoxTypography.caption)
                .foregroundStyle(toneColor(tone))
        }
    }

    private func toneColor(_ tone: NoxCapabilityTone) -> Color {
        switch tone {
        case .active:
            NoxDesignTokens.ColorRole.presenceActive
        case .building:
            NoxDesignTokens.ColorRole.accent
        case .pending:
            NoxDesignTokens.ColorRole.textSecondary
        case .locked:
            NoxDesignTokens.ColorRole.textSecondary.opacity(0.7)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
            .overlay {
                RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(NoxDesignTokens.Opacity.divider))
            }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(NoxTypography.sectionLabel)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            .tracking(0.6)
    }

    private func sectionSubtitle(_ text: String) -> some View {
        Text(text)
            .font(NoxTypography.caption)
            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.85))
    }
}

#Preview {
    NoxSystemStatusView()
        .environment(AppEnvironment())
        .padding()
        .frame(width: NoxDesignTokens.Window.width)
}
