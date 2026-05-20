import SwiftUI

/// Find My-inspired hardware presence: recognizable silhouettes over protocol icons.
struct NoxPresenceDeviceVisual: View {
    let kind: NoxPresenceDeviceKind
    let tone: NoxPresenceCardTone
    var large: Bool = false
    var isGroupedDevice = false

    @State private var pulse = false

    private var canvasWidth: CGFloat { large ? 220 : 176 }
    private var canvasHeight: CGFloat { large ? 180 : 132 }

    var body: some View {
        ZStack {
            auroraField
            hardware
                .scaleEffect(large ? 1.14 : 1)
                .shadow(color: Color.black.opacity(0.32), radius: large ? 22 : 18, y: large ? 16 : 14)
                .shadow(color: glowColor.opacity(pulse ? 0.42 : 0.18), radius: pulse ? 28 : 14)
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .onAppear {
            guard tone == .nearby || tone == .expanding else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private var hardware: some View {
        switch kind {
        case .iMac:
            iMac
        case .macBookPro, .macBookAir, .mac:
            macBook
        case .macStudio:
            macStudio
        case .macMini, .appleTV:
            roundedSetTop
        case .iPhone:
            iPhone
        case .iPad:
            iPad
        case .appleWatch:
            appleWatch
        case .homePod:
            if isGroupedDevice {
                homePodPair
            } else {
                homePod
            }
        }
    }

    private var auroraField: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(pulse ? 0.34 : 0.2),
                            NoxDesignTokens.ColorRole.accent.opacity(0.06),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: pulse ? 92 : 74
                    )
                )
                .frame(width: 168, height: 106)
                .blur(radius: 10)
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 112, height: 5)
                .offset(y: 54)
                .blur(radius: 2)
        }
    }

    private var macBook: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(deviceGradient)
                .frame(width: 122, height: 76)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                )
                .offset(y: -14)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(metalGradient)
                .frame(width: 154, height: 12)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.18))
                        .frame(width: 36, height: 3)
                        .offset(y: -2)
                )
        }
    }

    private var iMac: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(deviceGradient)
                    .frame(width: 124, height: 82)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.34), lineWidth: 1)
                    )
                Rectangle()
                    .fill(metalGradient)
                    .frame(width: 16, height: 22)
                Capsule(style: .continuous)
                    .fill(metalGradient)
                    .frame(width: 58, height: 8)
            }
        }
    }

    private var iPhone: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(deviceGradient)
            .frame(width: 68, height: 118)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
                    .padding(3)
            )
            .overlay(alignment: .top) {
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .frame(width: 22, height: 5)
                    .padding(.top, 9)
            }
    }

    private var iPad: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(deviceGradient)
            .frame(width: 96, height: 124)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.32), lineWidth: 1)
                    .padding(4)
            )
    }

    private var homePod: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.84),
                        Color.white.opacity(0.44),
                        NoxDesignTokens.ColorRole.accent.opacity(0.22),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 82, height: 112)
            .overlay(
                VStack(spacing: 5) {
                    ForEach(0 ..< 11, id: \.self) { _ in
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.055))
                            .frame(width: 56, height: 1)
                    }
                }
            )
    }

    private var homePodPair: some View {
        ZStack {
            homePod
                .scaleEffect(0.88)
                .offset(x: -24, y: 4)
                .opacity(0.86)
            homePod
                .scaleEffect(0.92)
                .offset(x: 24, y: -2)
        }
    }

    private var appleWatch: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(metalGradient.opacity(0.78))
                .frame(width: 38, height: 130)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(deviceGradient)
                .frame(width: 72, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                        .padding(4)
                )
        }
    }

    private var macStudio: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(metalGradient)
            .frame(width: 104, height: 82)
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.white.opacity(0.26), lineWidth: 1)
                    .padding(3)
            )
    }

    private var roundedSetTop: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(metalGradient)
            .frame(width: 108, height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .rotation3DEffect(.degrees(58), axis: (x: 1, y: 0, z: 0))
    }

    private var deviceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.94),
                NoxDesignTokens.ColorRole.accent.opacity(0.52),
                Color.black.opacity(0.24),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var metalGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.78),
                NoxDesignTokens.ColorRole.textSecondary.opacity(0.36),
                Color.black.opacity(0.28),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowColor: Color {
        switch tone {
        case .trusted:
            NoxDesignTokens.ColorRole.accent.opacity(0.84)
        case .awaitingTrust:
            NoxDesignTokens.ColorRole.presenceActive
        case .nearby, .expanding:
            NoxDesignTokens.ColorRole.presenceActive
        case .unavailable:
            NoxDesignTokens.ColorRole.presenceMuted
        }
    }
}
