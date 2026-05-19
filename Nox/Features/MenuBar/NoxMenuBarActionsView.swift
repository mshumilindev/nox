import AppKit
import SwiftUI

struct NoxMenuBarActionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.noxMenuBarDismiss) private var closeMenuBar
    @Environment(AppEnvironment.self) private var environment
    @Environment(NoxPanelState.self) private var panelState

    var body: some View {
        VStack(spacing: 0) {
            openAction

            Divider()
                .opacity(NoxDesignTokens.Opacity.divider)
                .padding(.vertical, NoxSpacing.sm)

            quitAction
        }
    }

    private var openAction: some View {
        Button {
            closeMenuBarPanel()
            Task { @MainActor in
                panelState.openDashboard(using: environment)
            }
        } label: {
            actionLabel(title: "Open Nox", symbolName: "macwindow")
        }
        .buttonStyle(.noxBorderless(hover: .row))
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
        .keyboardShortcut("o", modifiers: .command)
        .accessibilityLabel("Open Nox")
        .accessibilityHint("Opens the floating Nox presence panel.")
    }

    private var quitAction: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            actionLabel(title: "Quit Nox", symbolName: "power")
        }
        .buttonStyle(.noxBorderless(hover: .row))
        .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
        .accessibilityLabel("Quit Nox")
        .accessibilityHint("Closes the Nox menu bar app.")
    }

    private func actionLabel(title: String, symbolName: String) -> some View {
        HStack(spacing: NoxSpacing.sm) {
            Text(title)
                .font(NoxTypography.action)
            Spacer()
            Image(systemName: symbolName)
                .font(.system(size: NoxDesignTokens.SymbolSize.sm, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, NoxSpacing.xs)
        .padding(.vertical, NoxSpacing.sm)
        .contentShape(Rectangle())
    }

    private func closeMenuBarPanel() {
        closeMenuBar?()
        dismiss()
    }
}

#Preview {
    NoxMenuBarActionsView()
        .environment(AppEnvironment())
        .environment(NoxPanelState())
        .padding()
        .frame(width: NoxSpacing.menuBarWidth)
}
