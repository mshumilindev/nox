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

// MARK: - Nox atmospheric palette (Constellation / aurora language)

enum NoxAtmosphericModalPalette {
    static let graphite = Color(hex: 0x050914)
    static let deepBlueBlack = Color(hex: 0x02050D)
    static let auroraHaze = Color(hex: 0x1B2442)
    static let violetMist = Color(hex: 0x2A2450)

    static var accent: Color { NoxDesignTokens.ColorRole.accent }
    static var presence: Color { NoxDesignTokens.ColorRole.presenceActive }
    static var border: Color { NoxDesignTokens.ColorRole.border }
}

// MARK: - Modal shell

/// Deep-space translucent panel — Nox atmosphere, not system gray acrylic.
struct NoxAtmosphericModalSurface<Content: View>: View {
    var cornerRadius: CGFloat = NoxDesignTokens.Radius.lg
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .background { atmosphericPlate }
            .clipShape(shape)
            .overlay { luminousRim }
            .shadow(color: NoxAtmosphericModalPalette.accent.opacity(0.16), radius: 32, y: 14)
            .shadow(color: Color.black.opacity(0.38), radius: 20, y: 8)
    }

    private var atmosphericPlate: some View {
        ZStack {
            shape
                .fill(.ultraThinMaterial.opacity(0.22))

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            NoxAtmosphericModalPalette.graphite.opacity(0.82),
                            NoxAtmosphericModalPalette.deepBlueBlack.opacity(0.88),
                            NoxAtmosphericModalPalette.graphite.opacity(0.78),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            shape
                .fill(
                    RadialGradient(
                        colors: [
                            NoxAtmosphericModalPalette.auroraHaze.opacity(0.22),
                            NoxAtmosphericModalPalette.violetMist.opacity(0.08),
                            Color.clear,
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 280
                    )
                )

            shape
                .fill(
                    RadialGradient(
                        colors: [
                            NoxAtmosphericModalPalette.presence.opacity(0.06),
                            Color.clear,
                        ],
                        center: .bottomTrailing,
                        startRadius: 4,
                        endRadius: 200
                    )
                )

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.09),
                            Color.white.opacity(0.02),
                            Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.42)
                    )
                )
        }
    }

    private var luminousRim: some View {
        shape
            .strokeBorder(
                LinearGradient(
                    colors: [
                        NoxAtmosphericModalPalette.accent.opacity(0.28),
                        NoxAtmosphericModalPalette.border.opacity(0.14),
                        NoxAtmosphericModalPalette.presence.opacity(0.1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}

// MARK: - Modal controls

struct NoxAtmosphericModalButton: View {
    enum Kind { case primary, secondary }

    let title: String
    let kind: Kind
    let action: () -> Void

    @State private var hovering = false

    private var cornerRadius: CGFloat { NoxDesignTokens.Radius.sm }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: kind == .primary ? .semibold : .medium))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, NoxSpacing.sm)
                .padding(.horizontal, NoxSpacing.md)
                .background { buttonPlate }
                .overlay { buttonRim }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
    }

    private var labelColor: Color {
        switch kind {
        case .primary:
            NoxDesignTokens.ColorRole.textPrimary.opacity(hovering ? 1 : 0.94)
        case .secondary:
            NoxDesignTokens.ColorRole.textSecondary.opacity(hovering ? 0.9 : 0.76)
        }
    }

    @ViewBuilder
    private var buttonPlate: some View {
        let rounded = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            rounded
                .fill(NoxAtmosphericModalPalette.graphite.opacity(kind == .primary ? 0.55 : 0.68))

            if kind == .primary {
                rounded
                    .fill(
                        LinearGradient(
                            colors: [
                                NoxAtmosphericModalPalette.accent.opacity(hovering ? 0.34 : 0.2),
                                NoxAtmosphericModalPalette.presence.opacity(hovering ? 0.14 : 0.06),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                rounded
                    .fill(
                        LinearGradient(
                            colors: [
                                NoxAtmosphericModalPalette.auroraHaze.opacity(hovering ? 0.18 : 0.08),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            if hovering {
                rounded
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(kind == .primary ? 0.1 : 0.06),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        }
        .shadow(
            color: kind == .primary && hovering
                ? NoxAtmosphericModalPalette.accent.opacity(0.32)
                : Color.clear,
            radius: 12,
            y: 2
        )
    }

    private var buttonRim: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                NoxAtmosphericModalPalette.accent.opacity(
                    kind == .primary ? (hovering ? 0.36 : 0.22) : (hovering ? 0.18 : 0.1)
                ),
                lineWidth: 0.5
            )
    }
}

struct NoxAtmosphericModalCloseButton: View {
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(
                    NoxDesignTokens.ColorRole.textSecondary.opacity(hovering ? 0.95 : 0.78)
                )
                .frame(width: 28, height: 28)
                .background { closePlate }
                .overlay { closeRim }
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
    }

    @ViewBuilder
    private var closePlate: some View {
        Circle()
            .fill(NoxAtmosphericModalPalette.graphite.opacity(0.5))
            .overlay {
                if hovering {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    NoxAtmosphericModalPalette.accent.opacity(0.28),
                                    Color.clear,
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 18
                            )
                        )
                }
            }
    }

    private var closeRim: some View {
        Circle()
            .strokeBorder(
                NoxAtmosphericModalPalette.accent.opacity(hovering ? 0.28 : 0.12),
                lineWidth: 0.5
            )
    }
}

// MARK: - Legacy aliases (call sites)

typealias NoxLiquidGlassModalSurface = NoxAtmosphericModalSurface
typealias NoxLiquidGlassModalButton = NoxAtmosphericModalButton

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
