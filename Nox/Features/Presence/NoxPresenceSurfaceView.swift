import AppKit
import SwiftUI

/// Ambient Apple ecosystem presence — curated Nox environments, not LAN enumeration.
struct NoxPresenceSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var expandTarget: ExpandTarget?
    @State private var showDeveloperTools = false
    @State private var optionKeyDown = false

    private var mesh: PresenceMeshManager { environment.presenceMesh }

    var body: some View {
        NoxSurfacePage {
            NoxPageIntro(
                title: "Presence",
                subtitle: "Nox quietly senses nearby environments — only what matters to your ecosystem."
            )

            thisMacHero

            if let pending = mesh.pendingApproval, let kind = resolvedKind(for: pending.deviceName) {
                approvalCard(pending: pending, kind: kind)
            }

            if !mesh.isListeningForPresence {
                nearbyEnvironmentsSection
                trustedEnvironmentsSection
            }

            if showDeveloperTools || optionKeyDown {
                NoxPresenceDeveloperPanel()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: mesh.ambientNearbyNodes.map(\.deviceId))
        .animation(.easeInOut(duration: 0.35), value: mesh.isListeningForPresence)
        .background(NoxOptionKeyMonitor(optionDown: $optionKeyDown))
        .onAppear { mesh.setPresencePageActive(true) }
        .onDisappear { mesh.setPresencePageActive(false) }
        .sheet(item: $expandTarget) { target in
            NoxPresenceExpandSheet(
                deviceName: target.deviceName,
                deviceKind: target.kind,
                hardwareIdentity: target.hardwareIdentity,
                onBeginExpansion: {
                    Task { await mesh.expandToDevice(target.node) }
                },
                onInviteNearbyMac: { prepareAndShare() },
                onCopySetupLink: { copySetupLink() }
            )
        }
    }

    // MARK: - Hero

    private var thisMacHero: some View {
        let name = mesh.identity?.deviceName ?? "This Mac"
        let kind = resolvedKind(for: name) ?? .macBookPro
        return NoxPresenceDeviceCard(
            deviceName: name,
            kind: kind,
            hardwareIdentity: NoxPresenceHardwareIdentityResolver.hardwareIdentityForLocalMac(deviceName: name),
            tone: .trusted,
            onExpand: nil,
            onTrust: nil,
            onDecline: nil,
            onPulse: nil,
            isPrimaryEnvironment: true
        )
        .onTapGesture(count: 5) {
            #if DEBUG
            showDeveloperTools.toggle()
            #endif
        }
    }

    // MARK: - Sections

    private var nearbyEnvironmentsSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            Text("Nearby Environments")
                .noxSectionLabel()

            if mesh.ambientNearbyNodes.isEmpty {
                emptyNearbyState
            } else {
                ForEach(mesh.ambientNearbyNodes) { node in
                    if let kind = resolvedKind(for: node) {
                        let hardwareIdentity = NoxPresenceHardwareIdentityResolver.hardwareIdentity(
                            for: node,
                            expectedKind: kind
                        )
                        NoxPresenceDeviceCard(
                            deviceName: node.deviceName,
                            kind: kind,
                            hardwareIdentity: hardwareIdentity,
                            tone: cardTone(for: node),
                            onExpand: node.state == .unavailable ? nil : {
                                expandTarget = ExpandTarget(
                                    node: node,
                                    deviceName: node.deviceName,
                                    kind: kind,
                                    hardwareIdentity: hardwareIdentity
                                )
                            },
                            onTrust: nil,
                            onDecline: nil,
                            onPulse: node.state == .unavailable ? {
                                Task<Void, Never> { await mesh.sendAirPlayTestPulse(to: node.deviceId) }
                            } : nil,
                            subtitleOverride: subtitle(for: node, kind: kind),
                            isGroupedDevice: isGroupedDevice(node)
                        )
                    }
                }
            }
        }
    }

    private var trustedEnvironmentsSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            Text("Trusted Presence")
                .noxSectionLabel()

            if mesh.trustedNodes.isEmpty {
                emptyTrustedHint
            } else {
                ForEach(mesh.trustedNodes) { node in
                    if let kind = resolvedKind(for: node.trustedDeviceName) {
                        NoxPresenceDeviceCard(
                            deviceName: node.trustedDeviceName,
                            kind: kind,
                            hardwareIdentity: trustedHardwareIdentity(name: node.trustedDeviceName, kind: kind),
                            tone: .trusted,
                            onExpand: nil,
                            onTrust: nil,
                            onDecline: nil,
                            onPulse: { Task { await mesh.sendTestPulse(to: node.trustedNodeId) } }
                        )
                    }
                }
            }
        }
    }

    private var emptyNearbyState: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text("No nearby Nox presence yet.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
            Text("Nox quietly listens for nearby Apple environments.")
                .font(.system(size: 13))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NoxSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous)
                .fill(NoxMaterials.fill(for: .inset))
        )
        .overlay {
            NoxPresenceListeningView.AuroraBreath()
                .clipShape(RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.md, style: .continuous))
                .allowsHitTesting(false)
        }
    }

    private var emptyTrustedHint: some View {
        Text("Trusted environments will gather here — quietly, as you approve them.")
            .noxMetadata()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(NoxSpacing.lg)
            .noxSurface(.inset, padding: 0)
    }

    private func approvalCard(pending: NoxDiscoveredNode, kind: NoxPresenceDeviceKind) -> some View {
        NoxPresenceDeviceCard(
            deviceName: pending.deviceName,
            kind: kind,
            hardwareIdentity: NoxPresenceHardwareIdentityResolver.hardwareIdentity(for: pending, expectedKind: kind),
            tone: .awaitingTrust,
            onExpand: nil,
            onTrust: { Task { await mesh.trustPendingDevice() } },
            onDecline: { Task { await mesh.declinePendingDevice() } },
            onPulse: nil
        )
    }

    // MARK: - Helpers

    private func resolvedKind(for name: String) -> NoxPresenceDeviceKind? {
        NoxPresenceCurator.resolvedDeviceKind(for: name)
    }

    private func resolvedKind(for node: NoxDiscoveredNode) -> NoxPresenceDeviceKind? {
        NoxPresenceCurator.resolvedDeviceKind(for: node)
    }

    private func trustedHardwareIdentity(
        name: String,
        kind: NoxPresenceDeviceKind
    ) -> NoxPresenceHardwareIdentity {
        if let inferred = NoxPresenceDeviceKind.confidentlyInfer(from: name),
           let key = NoxPresenceFamilyArtwork.imageKey(for: inferred) {
            return NoxPresenceHardwareIdentity(
                confidence: .family,
                deviceKey: key,
                colorKey: NoxPresenceFamilyArtwork.defaultColor(for: key),
                fallbackKind: inferred,
                showsConcreteAppleDevice: true
            )
        }
        if let key = NoxPresenceFamilyArtwork.imageKey(for: kind) {
            return NoxPresenceHardwareIdentity(
                confidence: .family,
                deviceKey: key,
                colorKey: NoxPresenceFamilyArtwork.defaultColor(for: key),
                fallbackKind: kind,
                showsConcreteAppleDevice: true
            )
        }
        return .generic(fallbackKind: kind)
    }

    private func cardTone(for node: NoxDiscoveredNode) -> NoxPresenceCardTone {
        if node.state == .pairingRequested { return .expanding }
        if node.state == .unavailable { return .unavailable }
        return .nearby
    }

    private func subtitle(for node: NoxDiscoveredNode, kind: NoxPresenceDeviceKind) -> String? {
        if kind == .homePod, isGroupedDevice(node) {
            return "Stereo pair nearby"
        }
        if node.state == .unavailable {
            return "Nearby Apple ecosystem presence"
        }
        return nil
    }

    private func isGroupedDevice(_ node: NoxDiscoveredNode) -> Bool {
        node.appleGroupMemberNames.count > 1
    }

    private func prepareAndShare() {
        guard let payload = try? mesh.makeShareInvite() else { return }
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("nox-invite-\(UUID().uuidString).noxpair")
        try? payload.data.write(to: temp)
        NoxPresenceMeshShareBridge.presentShare(items: [temp, payload.plainText], from: nil)
    }

    private func copySetupLink() {
        guard let text = try? mesh.setupLinkText() else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

private struct ExpandTarget: Identifiable {
    let node: NoxDiscoveredNode
    let deviceName: String
    let kind: NoxPresenceDeviceKind
    let hardwareIdentity: NoxPresenceHardwareIdentity
    var id: String { node.deviceId }
}

private struct NoxOptionKeyMonitor: NSViewRepresentable {
    @Binding var optionDown: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
            optionDown = event.modifierFlags.contains(.option)
            return event
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var monitor: Any?
    }
}
