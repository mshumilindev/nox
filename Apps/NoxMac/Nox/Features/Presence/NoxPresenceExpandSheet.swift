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

struct NoxPresenceExpandSheet: View {
    let deviceName: String
    let roleLabel: String
    let roleSymbolName: String?
    let deviceArtwork: NoxConstellationDeviceArtworkPresentation
    let onBeginExpansion: () -> Void
    let onCopySetupLink: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    private let modalWidth: CGFloat = 400
    private let contentInset: CGFloat = NoxSpacing.lg

    var body: some View {
        NoxAtmosphericModalSurface {
            sheetContent
        }
        .frame(width: modalWidth)
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                appeared = true
            }
        }
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            header
            actionStack
        }
        .padding(contentInset)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: NoxSpacing.md) {
            deviceVisualAnchor
            textColumn
        }
        .overlay(alignment: .topTrailing) {
            NoxAtmosphericModalCloseButton {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel(NoxConstellationCopy.expandSheetClose)
        }
    }

    private var deviceVisualAnchor: some View {
        NoxPresenceDeviceVisual(
            identity: deviceArtwork.hardwareIdentity,
            tone: deviceArtwork.tone,
            large: false,
            isGroupedDevice: deviceArtwork.isGroupedDevice
        )
        .id(deviceArtwork.hardwareIdentity.cacheKey)
        .frame(width: 78, height: 62)
        .frame(width: 80, alignment: .center)
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
            Text(NoxConstellationCopy.expandSheetTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)

            Text(deviceName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
                .lineLimit(1)

            roleLabelRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 36)
    }

    private var roleLabelRow: some View {
        HStack(spacing: NoxSpacing.xxs) {
            if let roleSymbolName {
                NoxIcon(
                    systemName: roleSymbolName,
                    role: .inline,
                    tint: NoxDesignTokens.ColorRole.textSecondary.opacity(0.65)
                )
                .frame(width: 14, height: 14)
            }
            Text(roleLabel)
                .font(.system(size: 12))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.78))
                .lineLimit(1)
        }
        .padding(.top, 2)
    }

    // MARK: - Actions

    private var actionStack: some View {
        VStack(spacing: NoxSpacing.sm) {
            NoxAtmosphericModalButton(
                title: NoxConstellationCopy.beginExpansion,
                kind: .primary
            ) {
                onBeginExpansion()
                dismiss()
            }

            NoxAtmosphericModalButton(
                title: NoxConstellationCopy.copySetupLink,
                kind: .secondary
            ) {
                onCopySetupLink()
            }
        }
        .padding(.top, NoxSpacing.xs)
    }
}
