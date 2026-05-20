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

/// Non-blocking device artwork for Presence cards.
struct NoxDeviceArtworkView: View {
    let identity: NoxPresenceHardwareIdentity
    let tone: NoxPresenceCardTone
    var large: Bool = false
    var isGroupedDevice = false

    @State private var imageData: Data?
    @State private var imageOpacity: Double = 0
    @State private var pulse = false

    private var canvasWidth: CGFloat { large ? 136 : 78 }
    private var canvasHeight: CGFloat { large ? 106 : 62 }

    var body: some View {
        ZStack {
            auroraField
            NoxPresenceGenericDeviceArtwork(
                kind: identity.fallbackKind,
                isGroupedDevice: isGroupedDevice,
                ambientOnly: false
            )
            .opacity(imageData == nil ? 1 : 0)
            .scaleEffect(large ? 1.14 : 1)

            if let imageData, let image = NSImage(data: imageData) {
                loadedArtwork(image)
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .task(id: identity.cacheKey) {
            imageOpacity = 0
            imageData = nil
            let result = await DeviceArtworkResolver.shared.resolve(identity)
            guard !Task.isCancelled else { return }
            imageData = result.imageData
            if result.imageData != nil {
                withAnimation(.easeOut(duration: 0.32)) { imageOpacity = 1 }
            }
        }
        .onAppear {
            guard tone == .nearby || tone == .expanding else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    @ViewBuilder
    private func loadedArtwork(_ image: NSImage) -> some View {
        if isGroupedDevice && identity.fallbackKind == .homePod {
            ZStack {
                loadedImage(image)
                    .scaleEffect(0.9)
                    .offset(x: -9, y: 2)
                    .opacity(imageOpacity * 0.82)
                loadedImage(image)
                    .scaleEffect(0.94)
                    .offset(x: 9, y: -1)
                    .opacity(imageOpacity)
            }
        } else {
            loadedImage(image)
                .opacity(imageOpacity)
        }
    }

    private func loadedImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: canvasWidth * 0.88, maxHeight: canvasHeight * 0.92)
            .shadow(color: Color.black.opacity(0.28), radius: large ? 12 : 8, y: 5)
    }

    private var auroraField: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        glowColor.opacity(pulse ? 0.32 : 0.18),
                        NoxDesignTokens.ColorRole.accent.opacity(0.05),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: pulse ? 58 : 48
                )
            )
            .frame(width: large ? 116 : 66, height: large ? 72 : 44)
            .blur(radius: 7)
    }

    private var glowColor: Color {
        switch tone {
        case .trusted: NoxDesignTokens.ColorRole.accent.opacity(0.84)
        case .awaitingTrust, .nearby, .expanding: NoxDesignTokens.ColorRole.presenceActive
        case .unavailable: NoxDesignTokens.ColorRole.presenceMuted
        }
    }
}
