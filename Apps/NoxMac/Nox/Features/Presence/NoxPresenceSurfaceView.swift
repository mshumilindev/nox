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
import NoxShrineCore

/// Constellation — curated device ecosystem, not a network browser.
struct NoxPresenceSurfaceView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var expandTarget: ExpandTarget?
    @State private var showDeveloperTools = false
    @State private var optionKeyDown = false

    private var mesh: PresenceMeshManager { environment.presenceMesh }

    var body: some View {
        NoxSurfacePage {
            NoxPageIntro(
                title: NoxConstellationCopy.pageTitle,
                subtitle: NoxConstellationCopy.pageSubtitle
            )

            thisMacHero

            if let pending = mesh.pendingApproval, let kind = resolvedKind(for: pending.deviceName) {
                approvalCard(pending: pending, kind: kind)
            }

            if !mesh.isListeningForPresence {
                nearbyCandidatesSection
                trustedConstellationSection
                expandActionsSection
            }

            if showDeveloperTools || optionKeyDown {
                NoxPresenceDeveloperPanel()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: mesh.ambientNearbyNodes.map(\.deviceId))
        .animation(.easeInOut(duration: 0.35), value: mesh.isListeningForPresence)
        .background(NoxOptionKeyMonitor(optionDown: $optionKeyDown))
        .onAppear {
            mesh.setPresencePageActive(true)
        }
        .onDisappear { mesh.setPresencePageActive(false) }
        .sheet(item: $expandTarget) { target in
            NoxPresenceExpandSheet(
                deviceName: target.deviceName,
                roleLabel: target.roleLabel,
                roleSymbolName: target.roleSymbolName,
                deviceArtwork: target.deviceArtwork,
                onBeginExpansion: {
                    Task { await mesh.expandToDevice(target.node) }
                },
                onCopySetupLink: { copySetupLink() }
            )
            .presentationBackground(.clear)
            .presentationCornerRadius(14)
        }
    }

    // MARK: - Hero

    private var thisMacHero: some View {
        let name = mesh.identity?.deviceName ?? "This Mac"
        let kind = resolvedKind(for: name) ?? .macBookPro
        let isNoxI = NoxConstellationRoleResolver.isNoxIActiveOnThisDevice(isMacOSCanonicalApp: true)
        return NoxPresenceDeviceCard(
            deviceName: name,
            kind: kind,
            hardwareIdentity: NoxPresenceHardwareIdentityResolver.hardwareIdentityForLocalMac(deviceName: name),
            tone: .trusted,
            onExpand: nil,
            onTrust: nil,
            onDecline: nil,
            onPulse: nil,
            subtitleOverride: NoxConstellationCopy.currentDeviceSubtitle(isNoxIActive: isNoxI),
            primaryDetailOverride: NoxConstellationCopy.currentDeviceDetail(isNoxIActive: isNoxI),
            roleSymbolName: NoxConstellationRoleIconResolver.symbol(for: .noxI),
            isPrimaryEnvironment: true
        )
        .onTapGesture(count: 5) {
            #if DEBUG
            showDeveloperTools.toggle()
            #endif
        }
    }

    // MARK: - Sections

    private var nearbyCandidatesSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            Text(NoxConstellationCopy.sectionNearbyCandidates)
                .noxSectionLabel()

            if mesh.ambientNearbyNodes.isEmpty {
                emptyNearbyState
            } else {
                ForEach(mesh.ambientNearbyNodes) { node in
                    if let kind = resolvedKind(for: node) {
                        let tone = cardTone(for: node)
                        let deviceArtwork = deviceArtworkPresentation(for: node, kind: kind, tone: tone)
                        let presentation = candidatePresentation(
                            for: node,
                            kind: kind,
                            isGroupedDevice: deviceArtwork.isGroupedDevice
                        )
                        NoxPresenceDeviceCard(
                            deviceName: node.deviceName,
                            kind: kind,
                            hardwareIdentity: deviceArtwork.hardwareIdentity,
                            tone: tone,
                            onExpand: {
                                expandTarget = ExpandTarget(
                                    node: node,
                                    deviceName: node.deviceName,
                                    kind: kind,
                                    deviceArtwork: deviceArtwork,
                                    roleLabel: presentation.roleLabel,
                                    roleSymbolName: NoxConstellationRoleIconResolver.symbolForRoleLabel(
                                        presentation.roleLabel
                                    )
                                )
                            },
                            onTrust: nil,
                            onDecline: nil,
                            onPulse: nil,
                            subtitleOverride: presentation.roleLabel,
                            metadataOverride: presentation.metadata,
                            roleSymbolName: NoxConstellationRoleIconResolver.symbolForRoleLabel(presentation.roleLabel),
                            isGroupedDevice: deviceArtwork.isGroupedDevice
                        )
                    }
                }
            }
        }
    }

    private var trustedConstellationSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            Text(NoxConstellationCopy.sectionTrustedDevices)
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
                            onPulse: nil,
                            subtitleOverride: NoxConstellationCopy.trustedSubtitle(assignedRole: node.constellationRole),
                            roleSymbolName: node.constellationRole.map {
                                NoxConstellationRoleIconResolver.symbol(for: $0)
                            }
                        )
                    }
                }
            }
        }
    }

    private var expandActionsSection: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            Text(NoxConstellationCopy.sectionExpandActions)
                .noxSectionLabel()

            VStack(alignment: .leading, spacing: NoxSpacing.sm) {
                Text("Share a setup link or invite another Mac when you are ready.")
                    .font(.system(size: 13))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.82))

                HStack(spacing: NoxSpacing.sm) {
                    Button(NoxConstellationCopy.inviteDevice) {
                        prepareAndShare()
                    }
                    .buttonStyle(NoxPresenceGhostButtonStyle(emphasized: true))

                    Button(NoxConstellationCopy.copySetupLink) {
                        copySetupLink()
                    }
                    .buttonStyle(NoxPresenceGhostButtonStyle())
                }
            }
            .padding(NoxSpacing.lg)
            .noxSurface(.inset, padding: 0)
        }
    }

    private var emptyNearbyState: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            Text(NoxConstellationCopy.emptyNearbyTitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
            Text(NoxConstellationCopy.emptyNearbyDetail)
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
        Text(NoxConstellationCopy.emptyTrustedHint)
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

    private var constellationContext: NoxConstellationClassificationContext {
        NoxConstellationClassificationContext(hasConfiguredStation: mesh.hasConfiguredNoxStation)
    }

    private func deviceArtworkPresentation(
        for node: NoxDiscoveredNode,
        kind: NoxPresenceDeviceKind,
        tone: NoxPresenceCardTone
    ) -> NoxConstellationDeviceArtworkPresentation {
        .nearby(node: node, kind: kind, tone: tone)
    }

    private func candidatePresentation(
        for node: NoxDiscoveredNode,
        kind: NoxPresenceDeviceKind,
        isGroupedDevice: Bool
    ) -> NoxConstellationCandidatePresentation {
        NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: kind,
            isGroupedHomePodStereo: kind == .homePod && isGroupedDevice,
            context: constellationContext
        )
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
    let deviceArtwork: NoxConstellationDeviceArtworkPresentation
    let roleLabel: String
    let roleSymbolName: String?
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
