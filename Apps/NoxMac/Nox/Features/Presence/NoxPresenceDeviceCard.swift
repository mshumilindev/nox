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
import NoxShrineCore

/// Curated presence row — hardware-led, with quiet explicit actions.
struct NoxPresenceDeviceCard: View {
    let deviceName: String
    let kind: NoxPresenceDeviceKind
    let hardwareIdentity: NoxPresenceHardwareIdentity
    let tone: NoxPresenceCardTone
    let onExpand: (() -> Void)?
    let onTrust: (() -> Void)?
    let onDecline: (() -> Void)?
    let onPulse: (() -> Void)?
    var subtitleOverride: String?
    var primaryDetailOverride: String?
    var metadataOverride: String?
    var roleSymbolName: String?
    var isGroupedDevice = false
    var isPrimaryEnvironment = false

    @State private var appeared = false

    @ViewBuilder
    private func roleSubtitleLine(_ text: String) -> some View {
        HStack(spacing: NoxSpacing.xxs) {
            if let roleSymbolName {
                NoxIcon(
                    systemName: roleSymbolName,
                    role: .inline,
                    tint: NoxDesignTokens.ColorRole.textSecondary.opacity(0.65)
                )
                .frame(width: 14, height: 14)
            }
            Text(text)
                .font(.system(size: isPrimaryEnvironment ? 13 : 12))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.82))
        }
    }

    var body: some View {
        HStack(spacing: isPrimaryEnvironment ? NoxSpacing.lg : NoxSpacing.md) {
            NoxPresenceDeviceVisual(
                identity: hardwareIdentity,
                tone: tone,
                large: false,
                isGroupedDevice: isGroupedDevice
            )
                .id(hardwareIdentity.cacheKey)
                .frame(width: isPrimaryEnvironment ? 104 : 78, height: isPrimaryEnvironment ? 78 : 62)
                .padding(.leading, NoxSpacing.md)
            VStack(alignment: .leading, spacing: isPrimaryEnvironment ? NoxSpacing.xs : 3) {
                if isPrimaryEnvironment {
                    Text(NoxConstellationCopy.sectionCurrentDevice)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(NoxDesignTokens.ColorRole.accent.opacity(0.76))
                        .textCase(.uppercase)
                        .tracking(1.4)
                }
                Text(deviceName)
                    .font(.system(size: isPrimaryEnvironment ? 18 : 16, weight: .semibold))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                roleSubtitleLine(
                    subtitleOverride ?? NoxPresenceDeviceCopy.subtitle(for: kind, tone: tone)
                )
                if let primaryDetailOverride, isPrimaryEnvironment {
                    Text(primaryDetailOverride)
                        .font(.system(size: 12))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.72))
                }
                if let metadataOverride, !isPrimaryEnvironment {
                    Text(metadataOverride)
                        .font(.system(size: 11))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.65))
                }
            }
            Spacer(minLength: NoxSpacing.md)
            rowActions
                .padding(.trailing, NoxSpacing.lg)
        }
        .padding(.vertical, isPrimaryEnvironment ? NoxSpacing.md : NoxSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: isPrimaryEnvironment ? 104 : 84, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous))
        .shadow(color: glowColor.opacity(appeared ? (isPrimaryEnvironment ? 0.18 : 0.24) : 0), radius: tone == .trusted ? 8 : 14, y: 5)
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onTapGesture(count: 1) {
            if tone == .nearby || tone == .unavailable { onExpand?() }
            if tone == .awaitingTrust { onTrust?() }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var rowActions: some View {
        HStack(spacing: NoxSpacing.sm) {
            switch tone {
            case .nearby, .unavailable:
                if let onExpand {
                    Button("Expand", action: onExpand)
                        .buttonStyle(NoxPresenceGhostButtonStyle())
                }
            case .awaitingTrust:
                if let onTrust {
                    Button("Trust", action: onTrust)
                        .buttonStyle(NoxPresenceGhostButtonStyle())
                }
                if let onDecline {
                    Button("Not Now", action: onDecline)
                        .buttonStyle(NoxPresenceGhostButtonStyle(emphasized: false))
                }
            case .trusted:
                EmptyView()
            case .expanding:
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .fill(NoxMaterials.fill(for: tone == .trusted ? .standard : .soft))
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(isPrimaryEnvironment ? 0.2 : (tone == .trusted ? 0.1 : 0.16)),
                            .clear,
                        ],
                        center: isPrimaryEnvironment ? .leading : .top,
                        startRadius: 20,
                        endRadius: isPrimaryEnvironment ? 220 : 280
                    )
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .strokeBorder(
                NoxDesignTokens.ColorRole.accent.opacity(isPrimaryEnvironment ? 0.2 : 0.12),
                lineWidth: 0.5
            )
    }

    private var glowColor: Color {
        tone == .trusted ? NoxDesignTokens.ColorRole.accent : NoxDesignTokens.ColorRole.presenceActive
    }
}

struct NoxPresencePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(NoxDesignTokens.ColorRole.canvas)
            .padding(.horizontal, NoxSpacing.lg)
            .padding(.vertical, NoxSpacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.accent.opacity(configuration.isPressed ? 0.78 : 0.94))
            )
    }
}

struct NoxPresenceGhostButtonStyle: ButtonStyle {
    var emphasized: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(
                emphasized
                    ? NoxDesignTokens.ColorRole.textPrimary.opacity(configuration.isPressed ? 0.7 : 0.92)
                    : NoxDesignTokens.ColorRole.textSecondary.opacity(0.8)
            )
            .padding(.horizontal, NoxSpacing.md)
            .padding(.vertical, NoxSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.35 : 0.22))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
    }
}
