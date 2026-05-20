import SwiftUI

/// Full-window Presence listening — one triskelion, centered copy, graphite overlay.
struct NoxPresenceListeningOverlay: View {
    @State private var rotation: Double = 0
    @State private var breathe = false

    var body: some View {
        ZStack {
            overlayScrim
            listeningContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    private var overlayScrim: some View {
        ZStack {
            NoxDesignTokens.ColorRole.canvas.opacity(0.58)
            RadialGradient(
                colors: [
                    NoxDesignTokens.ColorRole.accent.opacity(breathe ? 0.1 : 0.04),
                    NoxDesignTokens.ColorRole.canvas.opacity(0.72),
                ],
                center: .center,
                startRadius: 40,
                endRadius: 420
            )
            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.clear,
                    Color.black.opacity(0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var listeningContent: some View {
        HStack(alignment: .center, spacing: NoxSpacing.md) {
            ZStack {
                Circle()
                    .fill(NoxDesignTokens.ColorRole.accent.opacity(breathe ? 0.2 : 0.1))
                    .frame(width: 52, height: 52)
                Image("NoxTriskelionMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(NoxDesignTokens.ColorRole.accent)
                    .rotationEffect(.degrees(rotation))
            }

            VStack(alignment: .leading, spacing: NoxSpacing.xs) {
                Text("Listening for nearby Nox presence…")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.92))
                Text("Nox quietly listens for nearby Apple environments.")
                    .font(.system(size: 12))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.78))
            }
        }
        .padding(.horizontal, NoxSpacing.lg)
        .padding(.vertical, NoxSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .fill(NoxMaterials.fill(for: .soft))
                .overlay(
                    RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                        .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.14), lineWidth: 0.5)
                )
        )
    }
}
