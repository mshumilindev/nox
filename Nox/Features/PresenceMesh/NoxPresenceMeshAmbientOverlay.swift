import SwiftUI

/// Full-window pulse feedback — scrim below traffic lights, centered triskelion, blocks interaction.
struct NoxPresenceMeshAmbientOverlay: View {
    let isLoading: Bool
    let event: NoxMeshAmbientEvent?
    let onDismiss: () -> Void

    @State private var dismissTask: Task<Void, Never>?

    private var isVisible: Bool {
        isLoading || event != nil
    }

    var body: some View {
        if isVisible {
            GeometryReader { geometry in
                let band = NoxTitlebarLayout.trafficLightBandHeight
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: band)
                        .allowsHitTesting(false)

                    ZStack {
                        overlayScrim
                        pulseStack
                    }
                    .frame(
                        width: geometry.size.width,
                        height: max(0, geometry.size.height - band)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: isLoading) { _, loading in
                if !loading, event != nil {
                    scheduleDismiss()
                } else {
                    cancelDismiss()
                }
            }
            .onAppear {
                if !isLoading, event != nil {
                    scheduleDismiss()
                }
            }
            .onDisappear {
                cancelDismiss()
            }
        }
    }

    private var overlayScrim: some View {
        NoxDesignTokens.ColorRole.canvas.opacity(0.62)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pulseStack: some View {
        VStack(spacing: NoxSpacing.md) {
            NoxRotatingTriskelionView(size: 40, isSpinning: isLoading)
                .frame(width: 40, height: 40)
                .allowsHitTesting(false)

            if let text = statusText {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.94))
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private var statusText: String? {
        if isLoading { return nil }
        guard let event else { return nil }
        return eventTitle(event)
    }

    private func scheduleDismiss() {
        cancelDismiss()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            onDismiss()
        }
    }

    private func cancelDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    private func eventTitle(_ event: NoxMeshAmbientEvent) -> String {
        switch event {
        case .trustEstablished(let name):
            "Nox presence expanded — \(name) joined"
        case .pulseReceived(let name):
            "Pulse received from \(name)"
        case .pulseSentConfirmed(let name):
            "Pulse reached \(name)"
        case .presenceExpanded:
            "Nox presence expanded"
        }
    }
}
