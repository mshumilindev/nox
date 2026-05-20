import SwiftUI
import AppKit
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

enum NoxAtmosphericState: String, Codable, Sendable {
    case night

    var isAnimated: Bool { false }

    var updateInterval: TimeInterval { 1 }

    var baseCanvas: Color {
        Color(hex: 0x02040B)
    }
}

/// Static atmospheric identity layer. Aurora/plasma rendering is intentionally
/// disabled; this keeps the graphite night identity without decorative motion.
struct NoxAtmosphereBackground: View {
    var density: Double = 0.45
    var state: NoxAtmosphericState = .night
    var presentation: NoxAtmospherePresentation = .window

    var body: some View {
        ZStack {
            Canvas(rendersAsynchronously: true) { context, size in
                var context = context
                NoxAtmosphereRenderer.drawBaseLayer(
                    in: &context,
                    size: size,
                    density: density,
                    state: state,
                    presentation: presentation
                )
            }

            if showsNightImage {
                Image("NoxNightAuroraBackground")
                    .resizable()
                    .scaledToFill()
                    .opacity(nightImageOpacity)
                    .saturation(0.82)
                    .contrast(0.92)
                    .brightness(-0.08)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color(hex: 0x02040B).opacity(0.24),
                                Color(hex: 0x02040B).opacity(0.42)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipped()
            }

            Canvas(rendersAsynchronously: true) { context, size in
                var context = context
                NoxAtmosphereRenderer.drawOpticalLayer(
                    in: &context,
                    size: size,
                    state: state,
                    presentation: presentation
                )
            }
        }
        .background(state.baseCanvas)
    }

    private var showsNightImage: Bool {
        NSImage(named: "NoxNightAuroraBackground") != nil
    }

    private var nightImageOpacity: Double {
        switch (presentation, state) {
        case (.menuBar, _):
            return 0.32
        default:
            return 0.34
        }
    }
}

nonisolated enum NoxAtmospherePresentation: Sendable {
    case window
    case menuBar
}

private enum NoxAtmosphereRenderer {
    static func drawBaseLayer(
        in context: inout GraphicsContext,
        size: CGSize,
        density: Double,
        state: NoxAtmosphericState,
        presentation: NoxAtmospherePresentation
    ) {
        drawBase(in: &context, size: size, state: state)
        drawNightDepth(in: &context, size: size, density: density, state: state, presentation: presentation)
        drawStars(in: &context, size: size, state: state, presentation: presentation)
    }

    static func drawOpticalLayer(
        in context: inout GraphicsContext,
        size: CGSize,
        state: NoxAtmosphericState,
        presentation: NoxAtmospherePresentation
    ) {
        drawWindowOptics(in: &context, size: size, state: state, presentation: presentation)
    }

    private static func drawBase(in context: inout GraphicsContext, size: CGSize, state: NoxAtmosphericState) {
        let rect = Path(CGRect(origin: .zero, size: size))
        context.fill(
            rect,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: 0x00020A),
                    Color(hex: 0x02050D),
                    Color(hex: 0x050914),
                    Color(hex: 0x010208)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    private static func drawNightDepth(
        in context: inout GraphicsContext,
        size: CGSize,
        density: Double,
        state: NoxAtmosphericState,
        presentation: NoxAtmospherePresentation
    ) {
        let rect = Path(CGRect(origin: .zero, size: size))
        let scale = presentation == .menuBar ? 0.45 : 1.0
        let depth = 0.72

        var haze = context
        haze.addFilter(.blur(radius: 18))
        haze.fill(
            rect,
            with: .radialGradient(
                Gradient(colors: [
                    Color(hex: 0x1B2442).opacity((0.10 + density * 0.04) * scale * depth),
                    .clear
                ]),
                center: CGPoint(x: size.width * 0.35, y: size.height * 0.12),
                startRadius: 8,
                endRadius: max(size.width, size.height) * 0.56
            )
        )
        haze.fill(
            rect,
            with: .radialGradient(
                Gradient(colors: [
                    Color(hex: 0x13231F).opacity(0.06 * scale * depth),
                    .clear
                ]),
                center: CGPoint(x: size.width * 0.74, y: size.height * 0.22),
                startRadius: 8,
                endRadius: max(size.width, size.height) * 0.48
            )
        )
    }

    private static func drawStars(
        in context: inout GraphicsContext,
        size: CGSize,
        state: NoxAtmosphericState,
        presentation: NoxAtmospherePresentation
    ) {
        guard presentation == .window else { return }
        let starCount = 32
        for index in 0..<starCount {
            let x = unitNoise(seed: 700 + index, value: 0.13) * size.width
            let y = unitNoise(seed: 900 + index, value: 0.41) * size.height * 0.48
            let opacity = 0.025 + unitNoise(seed: 1100 + index, value: 0.73) * 0.085
            let radius = 0.40 + unitNoise(seed: 1300 + index, value: 0.29) * 0.45
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)),
                with: .color(Color(hex: 0xD8E6EF).opacity(opacity))
            )
        }
    }

    private static func drawWindowOptics(
        in context: inout GraphicsContext,
        size: CGSize,
        state: NoxAtmosphericState,
        presentation: NoxAtmospherePresentation
    ) {
        let rect = Path(CGRect(origin: .zero, size: size))
        let lowerDepth = 0.46
        context.fill(
            rect,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: 0xE8ECF6).opacity(presentation == .menuBar ? 0.010 : 0.018),
                    .clear,
                    Color(hex: 0x010206).opacity(lowerDepth)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
        context.stroke(
            Path(CGRect(x: 0.25, y: 0.25, width: max(0, size.width - 0.5), height: max(0, size.height - 0.5))),
            with: .color(Color(hex: 0xE8ECF6).opacity(0.035)),
            lineWidth: 0.5
        )
    }

    private static func unitNoise(seed: Int, value: Double) -> Double {
        let result = sin(Double(seed) * 12.9898 + value * 78.233) * 43_758.5453
        return result - floor(result)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
