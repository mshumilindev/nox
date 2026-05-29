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

/// Full-window pulse feedback — centered triskelion, blocks interaction.
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
            ZStack {
                overlayScrim
                pulseStack
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { }
            .ignoresSafeArea()
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
            NoxHeartbeatTriskelionView(size: 40, isActive: isLoading)
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
            "\(name) joined your constellation"
        case .pulseReceived(let name):
            "Signal received from \(name)"
        case .pulseSentConfirmed(let name):
            "Signal reached \(name)"
        case .presenceExpanded:
            "Constellation expanded"
        }
    }
}
