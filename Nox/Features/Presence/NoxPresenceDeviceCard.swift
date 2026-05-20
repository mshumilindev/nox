import SwiftUI

/// Curated presence row — hardware-led, with quiet explicit actions.
struct NoxPresenceDeviceCard: View {
    let deviceName: String
    let kind: NoxPresenceDeviceKind
    let tone: NoxPresenceCardTone
    let onExpand: (() -> Void)?
    let onTrust: (() -> Void)?
    let onDecline: (() -> Void)?
    let onPulse: (() -> Void)?
    var subtitleOverride: String?
    var isGroupedDevice = false

    @State private var appeared = false

    var body: some View {
        HStack(spacing: NoxSpacing.lg) {
            NoxPresenceDeviceVisual(kind: kind, tone: tone, large: false, isGroupedDevice: isGroupedDevice)
                .frame(width: 132, height: 104)
                .padding(.leading, NoxSpacing.md)
            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                Text(deviceName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                Text(subtitleOverride ?? NoxPresenceDeviceCopy.subtitle(for: kind, tone: tone))
                    .font(.system(size: 13))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.82))
            }
            Spacer(minLength: NoxSpacing.md)
            rowActions
                .padding(.trailing, NoxSpacing.lg)
        }
        .padding(.vertical, NoxSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .background(cardBackground)
        .overlay(cardBorder)
        .clipShape(RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous))
        .shadow(color: glowColor.opacity(appeared ? 0.28 : 0), radius: tone == .trusted ? 10 : 18, y: 6)
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onTapGesture(count: 1) {
            if tone == .nearby { onExpand?() }
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
            case .nearby:
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
                if let onPulse {
                    Button("Pulse", action: onPulse)
                        .buttonStyle(NoxPresenceGhostButtonStyle())
                }
            case .unavailable:
                if let onPulse {
                    Button("AirPlay Test", action: onPulse)
                        .buttonStyle(NoxPresenceGhostButtonStyle())
                }
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
                            glowColor.opacity(tone == .trusted ? 0.1 : 0.16),
                            .clear,
                        ],
                        center: .top,
                        startRadius: 20,
                        endRadius: 280
                    )
                )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
            .strokeBorder(
                NoxDesignTokens.ColorRole.accent.opacity(0.12),
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
