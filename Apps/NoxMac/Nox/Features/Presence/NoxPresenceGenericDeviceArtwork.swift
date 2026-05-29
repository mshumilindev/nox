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

/// Nox-styled Apple-like silhouettes — tier-4 fallback (not SF Symbols).
struct NoxPresenceGenericDeviceArtwork: View {
    let kind: NoxPresenceDeviceKind
    var isGroupedDevice = false
    var ambientOnly = false

    var body: some View {
        if ambientOnly {
            ambientGlyph
        } else {
            hardwareShape
        }
    }

    @ViewBuilder
    private var hardwareShape: some View {
        switch kind {
        case .iMac: iMac
        case .macBookPro, .macBookAir, .mac: macBook
        case .macStudio: macStudio
        case .macMini, .appleTV: roundedSetTop
        case .iPhone: iPhone
        case .iPad: iPad
        case .appleWatch: appleWatch
        case .homePod:
            if isGroupedDevice { homePodPair } else { homePod }
        }
    }

    private var ambientGlyph: some View {
        hardwareShape
    }

    private var macBook: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(deviceGradient)
                .frame(width: 122, height: 76)
                .offset(y: -14)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(metalGradient)
                .frame(width: 154, height: 12)
        }
    }

    private var iMac: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 9, style: .continuous).fill(deviceGradient).frame(width: 124, height: 82)
            Rectangle().fill(metalGradient).frame(width: 16, height: 22)
            Capsule(style: .continuous).fill(metalGradient).frame(width: 58, height: 8)
        }
    }

    private var iPhone: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(deviceGradient)
            .frame(width: 68, height: 118)
    }

    private var iPad: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(deviceGradient)
            .frame(width: 96, height: 124)
    }

    private var homePod: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(deviceGradient)
            .frame(width: 82, height: 112)
    }

    private var homePodPair: some View {
        ZStack {
            homePod.scaleEffect(0.88).offset(x: -24, y: 4).opacity(0.86)
            homePod.scaleEffect(0.92).offset(x: 24, y: -2)
        }
    }

    private var appleWatch: some View {
        ZStack {
            Capsule(style: .continuous).fill(metalGradient.opacity(0.78)).frame(width: 38, height: 130)
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(deviceGradient).frame(width: 72, height: 88)
        }
    }

    private var macStudio: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(metalGradient).frame(width: 104, height: 82)
    }

    private var roundedSetTop: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(metalGradient)
            .frame(width: 108, height: 46)
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
}
