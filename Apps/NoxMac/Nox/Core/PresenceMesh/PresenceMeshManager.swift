import Foundation
import CryptoKit
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
import Observation

enum NoxPresenceDiscoveryPhase: Equatable, Sendable {
    case idle
    case listening
}

@Observable
@MainActor
final class PresenceMeshManager {
    private(set) var identity: NoxNodeIdentity?
    private(set) var nearbyNodes: [NoxDiscoveredNode] = []
    private(set) var trustedNodes: [NoxTrustedNode] = []
    private(set) var thisNodeState: NoxPresenceNodeState = .thisDevice
    private(set) var isRunning = false
    private(set) var lastAmbientEvent: NoxMeshAmbientEvent?
    private(set) var isAmbientPulseBusy = false
    private(set) var pendingApproval: NoxDiscoveredNode?
    private(set) var pairingSessionDeviceId: String?
    private(set) var discoveryPhase: NoxPresenceDiscoveryPhase = .idle
    private(set) var isPresencePageActive = false

    let profile: NoxMeshProfile
    var diagnostics: [String] { NoxPresenceMeshDiagnostics.recentLines }

    /// Curated Nox environments only — never AirPlay, LAN noise, or low-confidence guesses.
    var ambientNearbyNodes: [NoxDiscoveredNode] {
        let selfId = identity?.deviceId
        return nearbyNodes.filter { node in
            node.deviceId != selfId
                && node.state != .trusted
                && NoxPresenceCurator.isPresentableNoxEnvironment(node)
        }
        .sorted { lhs, rhs in
            let lhsRank = presenceSortRank(lhs)
            let rhsRank = presenceSortRank(rhs)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return (discoveryOrder[lhs.deviceId] ?? Int.max) < (discoveryOrder[rhs.deviceId] ?? Int.max)
        }
    }

    var isListeningForPresence: Bool {
        isPresencePageActive && discoveryPhase == .listening && ambientNearbyNodes.isEmpty && trustedNodes.isEmpty
    }

    /// True only when a trusted device has an explicit Nox Station role assigned.
    var hasConfiguredNoxStation: Bool {
        NoxConstellationRoleResolver.hasConfiguredStation(in: trustedNodes)
    }

    private let identityProvider: LocalIdentityProvider
    private let discovery: CompositePresenceDiscoveryProvider
    private let transport: LocalHTTPPresenceTransport
    private let trustedStore = TrustedNodeStore()
    private let inviteService = PairingInviteService()
    private let verifier = PairingMessageVerifier()
    private var presenceToken = UUID().uuidString.prefix(8).description
    private var publicKeyBase64: String?
    private var pendingChallenges: [String: String] = [:]
    private var debounceNearbyTask: Task<Void, Never>?
    private var periodicDiscoveryTask: Task<Void, Never>?
    private var discoveryOrder: [String: Int] = [:]
    private var nextDiscoveryOrder = 0
    private var lastNearbySignature = ""

    init(profile: NoxMeshProfile = NoxMeshRuntime.profile) {
        self.profile = profile
        self.identityProvider = LocalIdentityProvider(profile: profile)
        self.discovery = CompositePresenceDiscoveryProvider()
        self.transport = LocalHTTPPresenceTransport()
    }

    /// Starts mesh transport when needed (pairing, trusted nodes, or Presence UI).
    func ensureStarted() {
        if isRunning { return }
        start()
    }

    func start() {
        guard !isRunning else { return }
        Task {
            do {
                let id = try identityProvider.loadOrCreateIdentity()
                let pub = try identityProvider.publicKey()
                publicKeyBase64 = pub.rawRepresentation.base64EncodedString()
                identity = id
                thisNodeState = .trusted

                transport.onMessageReceived = { [weak self] message, _ in
                    Task { @MainActor in
                        await self?.handleIncoming(message)
                    }
                }
                discovery.onNodesChanged = { [weak self] nodes in
                    guard let manager = self else { return }
                    Task { @MainActor in
                        manager.mergeDiscovered(nodes)
                    }
                }

                let port = profile.meshPort
                try transport.startListening(port: port)
                try discovery.start(identity: id, port: port, presenceToken: presenceToken)
                discovery.setAppleBluetoothDiscoveryActive(isPresencePageActive)
                trustedNodes = trustedStore.all()
                isRunning = true
                NoxPresenceMeshDiagnostics.log("Presence mesh started [\(profile.displayName)] port \(port)")
                if isPresencePageActive {
                    await refreshDiscoverySweep()
                }
            } catch {
                thisNodeState = .error
                NoxPresenceMeshDiagnostics.log("Mesh start failed: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        discovery.stop()
        transport.stopListening()
        isRunning = false
        discoveryPhase = .idle
    }

    // MARK: - Presence page lifecycle

    func setPresencePageActive(_ active: Bool) {
        isPresencePageActive = active
        if active, !isRunning {
            start()
        }
        discovery.setAppleBluetoothDiscoveryActive(active)
        periodicDiscoveryTask?.cancel()
        periodicDiscoveryTask = nil
        guard active else {
            discoveryPhase = .idle
            return
        }
        if isRunning {
            trustedNodes = trustedStore.all()
        }
        discoveryPhase = .listening
        Task { await refreshDiscoverySweep() }
        periodicDiscoveryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                await self?.refreshDiscoverySweep()
            }
        }
    }

    func refreshDiscoverySweep() async {
        guard isRunning, identity != nil else {
            guard isPresencePageActive else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, isPresencePageActive, isRunning, identity != nil else { return }
            await refreshDiscoverySweep()
            return
        }
        if ambientNearbyNodes.isEmpty && trustedNodes.isEmpty {
            discoveryPhase = .listening
        }
        try? await Task.sleep(for: .seconds(4))
        if isPresencePageActive {
            discoveryPhase = ambientNearbyNodes.isEmpty && trustedNodes.isEmpty ? .listening : .idle
        }
    }

    func resetIdentity() {
        stop()
        verifier.reset()
        trustedStore.reset()
        trustedNodes = []
        nearbyNodes = []
        pendingApproval = nil
        pairingSessionDeviceId = nil
        do {
            identity = try identityProvider.resetIdentity()
            let pub = try identityProvider.publicKey()
            publicKeyBase64 = pub.rawRepresentation.base64EncodedString()
            start()
        } catch {
            thisNodeState = .error
        }
    }

    // MARK: - Pairing

    func requestJoin(_ node: NoxDiscoveredNode) async {
        guard let identity, let publicKeyBase64 else { return }
        pairingSessionDeviceId = node.deviceId
        updateNodeState(node.deviceId, state: .pairingRequested)
        do {
            var msg = baseMessage(type: .pairingRequest, identity: identity)
            msg.publicKeyBase64 = publicKeyBase64
            msg.publicKeyFingerprint = identity.publicKeyFingerprint
            msg.systemId = identity.systemId
            msg.pairingPort = Int(profile.meshPort)
            try await signAndSend(&msg, to: node)
            NoxPresenceMeshDiagnostics.log("Pairing request sent to \(node.deviceName)")
        } catch {
            updateNodeState(node.deviceId, state: .error)
        }
    }

    func approvePendingJoin() async {
        guard let node = pendingApproval, let identity, let publicKeyBase64 else { return }
        do {
            var approved = baseMessage(type: .pairingApproved, identity: identity)
            approved.systemId = identity.systemId
            approved.publicKeyBase64 = publicKeyBase64
            approved.publicKeyFingerprint = identity.publicKeyFingerprint
            approved.pairingPort = Int(profile.meshPort)
            try await signAndSend(&approved, to: node)
            establishTrust(with: node, publicKey: node.publicKeyBase64 ?? publicKeyBase64)
            pendingApproval = nil
            updateNodeState(node.deviceId, state: .trusted)
            emitAmbient(.trustEstablished(deviceName: node.deviceName))
            NoxPresenceMeshDiagnostics.log("Approval sent to \(node.deviceName)")
        } catch {
            NoxPresenceMeshDiagnostics.log("Approval failed: \(error.localizedDescription)")
        }
    }

    func rejectPendingJoin() async {
        guard let node = pendingApproval, let identity else { return }
        var rejected = baseMessage(type: .pairingRejected, identity: identity)
        try? await signAndSend(&rejected, to: node)
        pendingApproval = nil
        updateNodeState(node.deviceId, state: .rejected)
    }

    func manualConnect(host: String, port: Int, deviceId: String, deviceName: String) async {
        let node = NoxDiscoveredNode(
            deviceId: deviceId,
            deviceName: deviceName,
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "",
            pairingPort: port,
            state: .nearby,
            lastSeenAt: Date(),
            hostName: host
        )
        nearbyNodes.append(node)
        await requestJoin(node)
    }

    func importInviteData(_ data: Data) async throws {
        let invite = try inviteService.decodeFile(data)
        try inviteService.validate(invite)
        let node = NoxDiscoveredNode(
            deviceId: invite.primaryDeviceId,
            deviceName: invite.primaryDeviceName,
            protocolVersion: invite.protocolVersion,
            publicKeyFingerprint: "",
            presenceToken: invite.inviteToken,
            pairingPort: invite.pairingPort,
            state: .nearby,
            lastSeenAt: Date(),
            systemId: invite.systemId,
            publicKeyBase64: invite.publicKeyBase64,
            hostName: "127.0.0.1"
        )
        if !nearbyNodes.contains(where: { $0.deviceId == node.deviceId }) {
            nearbyNodes.append(node)
        }
        await requestJoin(node)
    }

    func makeShareInvite() throws -> (data: Data, plainText: String) {
        guard let identity, let publicKeyBase64 else { throw NoxMeshError.identityUnavailable }
        let keyData = try identityProvider.signingPrivateKey()
        let invite = try inviteService.makeInvite(
            identity: identity,
            publicKeyBase64: publicKeyBase64,
            pairingPort: Int(profile.meshPort),
            privateKeyData: keyData
        )
        let data = try inviteService.encodeFile(invite)
        return (data, inviteService.sharePlainText(invite))
    }

    func setupLinkText() throws -> String {
        try makeShareInvite().plainText
    }

    func expandToDevice(_ node: NoxDiscoveredNode) async {
        await requestJoin(node)
    }

    func trustPendingDevice() async {
        await approvePendingJoin()
    }

    func declinePendingDevice() async {
        await rejectPendingJoin()
    }

    func launchSimulatedSecondaryNode() async {
        let targetPort = profile.name == "node-a" ? 9122 : 9121
        await manualConnect(
            host: "127.0.0.1",
            port: targetPort,
            deviceId: UUID().uuidString.lowercased(),
            deviceName: "MacBook Pro"
        )
    }

    // MARK: - Test messages

    func sendTestPulse(to deviceId: String) async {
        await sendTest(type: .testPulse, deviceId: deviceId, label: "pulse")
    }

    func sendTestPing(to deviceId: String) async {
        await sendTest(type: .testPing, deviceId: deviceId, label: "ping")
    }

    func sendAirPlayTestPulse(to deviceId: String) async {
        guard let node = nearbyNodes.first(where: { $0.deviceId == deviceId }),
              node.state == .unavailable else {
            NoxPresenceMeshDiagnostics.log("AirPlay test unavailable")
            return
        }
        let startedAt = Date()
        isAmbientPulseBusy = true

        guard let host = node.hostName, node.pairingPort > 0 else {
            await finishAirPlayTestLoading(startedAt: startedAt)
            NoxPresenceMeshDiagnostics.log("AirPlay test confirmed nearby presence for \(node.deviceName)")
            emitAmbient(.pulseSentConfirmed(deviceName: node.deviceName))
            return
        }
        let hostLiteral = host.hasSuffix(".") ? String(host.dropLast()) : host
        guard let url = URL(string: "http://\(hostLiteral):\(node.pairingPort)/info") else {
            await finishAirPlayTestLoading(startedAt: startedAt)
            NoxPresenceMeshDiagnostics.log("AirPlay test target unavailable")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        do {
            _ = try await URLSession.shared.data(for: request)
            await finishAirPlayTestLoading(startedAt: startedAt)
            NoxPresenceMeshDiagnostics.log("AirPlay test pulse reached \(node.deviceName)")
            emitAmbient(.pulseSentConfirmed(deviceName: node.deviceName))
        } catch {
            await finishAirPlayTestLoading(startedAt: startedAt)
            NoxPresenceMeshDiagnostics.log("AirPlay test pulse did not reach \(node.deviceName)")
        }
    }

    private func finishAirPlayTestLoading(startedAt: Date) async {
        let elapsed = Date().timeIntervalSince(startedAt)
        let minimumDuration: TimeInterval = 0.85
        if elapsed < minimumDuration {
            try? await Task.sleep(for: .milliseconds(Int((minimumDuration - elapsed) * 1000)))
        }
        isAmbientPulseBusy = false
    }

    private func sendTest(type: NoxMeshMessageType, deviceId: String, label: String) async {
        guard let identity else { return }
        let discovered: NoxDiscoveredNode
        if let nearby = nearbyNodes.first(where: { $0.deviceId == deviceId }) {
            discovered = nearby
        } else if let trusted = trustedNodes.first(where: { $0.trustedNodeId == deviceId }) {
            discovered = NoxDiscoveredNode(
                deviceId: trusted.trustedNodeId,
                deviceName: trusted.trustedDeviceName,
                protocolVersion: trusted.protocolVersion,
                publicKeyFingerprint: trusted.publicKeyFingerprint,
                presenceToken: "",
                pairingPort: trusted.lastPairingPort ?? Int(profile.meshPort),
                state: .trusted,
                lastSeenAt: Date(),
                hostName: trusted.lastHost ?? "127.0.0.1"
            )
        } else {
            return
        }
        var msg = baseMessage(type: type, identity: identity)
        msg.message = label
        do {
            try await signAndSend(&msg, to: discovered)
            NoxPresenceMeshDiagnostics.log("Test \(label) sent to \(discovered.deviceName)")
        } catch {
            NoxPresenceMeshDiagnostics.log("Test send failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Incoming

    private func handleIncoming(_ message: NoxMeshMessage) async {
        do {
            let key = message.publicKeyBase64
            if message.requiresSignature {
                try verifier.verify(message, publicKeyBase64: key, trustEstablishing: true)
            }
        } catch {
            return
        }

        switch message.type {
        case .pairingRequest:
            guard NoxPresenceCurator.displayEnvironmentName(message.fromDeviceName) != nil else {
                NoxPresenceMeshDiagnostics.log("Ignored pairing request with low-confidence identity")
                return
            }
            NoxPresenceMeshDiagnostics.log("Pairing request received from \(message.fromDeviceName)")
            let node = nodeFromMessage(message)
            pendingApproval = node
            pairingSessionDeviceId = node.deviceId
            updateNodeState(node.deviceId, state: .awaitingApproval)
            if !nearbyNodes.contains(where: { $0.deviceId == node.deviceId }) {
                nearbyNodes.append(node)
            }
        case .pairingApproved:
            if let node = nearbyNodes.first(where: { $0.deviceId == message.fromDeviceId }) {
                establishTrust(
                    with: node,
                    publicKey: message.publicKeyBase64 ?? node.publicKeyBase64 ?? ""
                )
                var trustMsg = baseMessage(type: .trustEstablished, identity: identity!)
                trustMsg.publicKeyBase64 = publicKeyBase64
                try? await signAndSend(&trustMsg, to: node)
                updateNodeState(node.deviceId, state: .trusted)
                emitAmbient(.trustEstablished(deviceName: node.deviceName))
            }
        case .pairingRejected:
            updateNodeState(message.fromDeviceId, state: .rejected)
        case .trustEstablished:
            if let node = nearbyNodes.first(where: { $0.deviceId == message.fromDeviceId }) {
                establishTrust(with: node, publicKey: message.publicKeyBase64 ?? "")
            }
        case .testPing:
            var pong = baseMessage(type: .testPong, identity: identity!)
            pong.message = message.nonce
            if let node = nearbyNodes.first(where: { $0.deviceId == message.fromDeviceId }) {
                try? await transport.send(pong, to: node.hostName ?? "127.0.0.1", port: node.pairingPort)
            }
            emitAmbient(.pulseReceived(deviceName: message.fromDeviceName))
        case .testPong:
            emitAmbient(.pulseSentConfirmed(deviceName: message.fromDeviceName))
        case .testPulse:
            emitAmbient(.pulseReceived(deviceName: message.fromDeviceName))
        case .presenceHello, .pairingChallenge, .pairingResponse:
            break
        }
    }

    // MARK: - Helpers

    private func mergeDiscovered(_ incoming: [NoxDiscoveredNode]) {
        debounceNearbyTask?.cancel()
        debounceNearbyTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            var merged = incoming
            if let pending = pendingApproval,
               let idx = merged.firstIndex(where: { $0.deviceId == pending.deviceId }) {
                merged[idx].state = .awaitingApproval
            }
            if let session = pairingSessionDeviceId,
               let idx = merged.firstIndex(where: { $0.deviceId == session }) {
                if pendingApproval == nil {
                    merged[idx].state = .pairingRequested
                }
            }
            for trusted in trustedStore.all() {
                if let idx = merged.firstIndex(where: { $0.deviceId == trusted.trustedNodeId }) {
                    merged[idx].state = .trusted
                    merged[idx].deviceName = trusted.trustedDeviceName
                } else {
                    merged.append(NoxDiscoveredNode(
                        deviceId: trusted.trustedNodeId,
                        deviceName: trusted.trustedDeviceName,
                        protocolVersion: trusted.protocolVersion,
                        publicKeyFingerprint: trusted.publicKeyFingerprint,
                        presenceToken: "",
                        pairingPort: Int(profile.meshPort),
                        state: .trusted,
                        lastSeenAt: trusted.lastSeenAt,
                        systemId: trusted.systemId,
                        publicKeyBase64: trusted.publicKeyBase64
                    ))
                }
            }
            let filtered = merged.filter { $0.deviceId != identity?.deviceId }
            for node in filtered where discoveryOrder[node.deviceId] == nil {
                discoveryOrder[node.deviceId] = nextDiscoveryOrder
                nextDiscoveryOrder += 1
            }
            let signature = nearbySignature(for: filtered)
            if signature != lastNearbySignature {
                lastNearbySignature = signature
                nearbyNodes = filtered
            }
            if isPresencePageActive {
                let hasPresence = !ambientNearbyNodes.isEmpty || !trustedNodes.isEmpty
                discoveryPhase = hasPresence ? .idle : .listening
            }
        }
    }

    private func establishTrust(with node: NoxDiscoveredNode, publicKey: String) {
        guard let identity else { return }
        let trusted = NoxTrustedNode(
            trustedNodeId: node.deviceId,
            trustedDeviceName: node.deviceName,
            publicKeyFingerprint: node.publicKeyFingerprint,
            publicKeyBase64: publicKey,
            trustCreatedAt: Date(),
            lastSeenAt: Date(),
            systemId: node.systemId ?? identity.systemId,
            protocolVersion: node.protocolVersion,
            lastHost: node.hostName,
            lastPairingPort: node.pairingPort > 0 ? node.pairingPort : Int(profile.meshPort)
        )
        trustedStore.upsert(trusted)
        trustedNodes = trustedStore.all()
        NoxPresenceMeshDiagnostics.log("Trust established with \(node.deviceName)")
    }

    private func nodeFromMessage(_ message: NoxMeshMessage) -> NoxDiscoveredNode {
        let name = NoxPresenceCurator.displayEnvironmentName(message.fromDeviceName) ?? message.fromDeviceName
        return NoxDiscoveredNode(
            deviceId: message.fromDeviceId,
            deviceName: name,
            protocolVersion: message.protocolVersion,
            publicKeyFingerprint: message.publicKeyFingerprint ?? "",
            presenceToken: message.inviteToken ?? "",
            pairingPort: message.pairingPort ?? Int(profile.meshPort),
            state: .awaitingApproval,
            lastSeenAt: Date(),
            systemId: message.systemId,
            publicKeyBase64: message.publicKeyBase64,
            hostName: "127.0.0.1"
        )
    }

    private func baseMessage(type: NoxMeshMessageType, identity: NoxNodeIdentity) -> NoxMeshMessage {
        NoxMeshMessage(
            type: type,
            protocolVersion: identity.protocolVersion,
            fromDeviceId: identity.deviceId,
            fromDeviceName: identity.deviceName,
            nonce: UUID().uuidString.lowercased(),
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func signAndSend(_ message: inout NoxMeshMessage, to node: NoxDiscoveredNode) async throws {
        let keyData = try identityProvider.signingPrivateKey()
        var extra: [String: String] = [:]
        if let systemId = message.systemId { extra["systemId"] = systemId }
        if let fp = message.publicKeyFingerprint { extra["publicKeyFingerprint"] = fp }
        if let inviteToken = message.inviteToken { extra["inviteToken"] = inviteToken }
        let payload = message.signingPayload(extra: extra)
        message.signature = try NoxMeshCrypto.sign(payload: payload, privateKeyData: keyData)
        let host = resolveHost(node)
        try await transport.send(message, to: host, port: node.pairingPort > 0 ? node.pairingPort : Int(profile.meshPort))
    }

    private func resolveHost(_ node: NoxDiscoveredNode) -> String {
        if let host = node.hostName, !host.isEmpty {
            return host
        }
        return "127.0.0.1"
    }

    private func updateNodeState(_ deviceId: String, state: NoxPresenceNodeState) {
        guard let idx = nearbyNodes.firstIndex(where: { $0.deviceId == deviceId }) else { return }
        nearbyNodes[idx].state = state
    }

    private func presenceSortRank(_ node: NoxDiscoveredNode) -> Int {
        guard let kind = NoxPresenceCurator.resolvedDeviceKind(for: node) else { return 50 }
        switch kind {
        case .iPhone: return 0
        case .iPad: return 1
        case .appleTV: return 2
        case .homePod: return 3
        case .iMac, .macBookPro, .macBookAir, .macStudio, .macMini, .mac: return 4
        case .appleWatch: return 5
        }
    }

    private func nearbySignature(for nodes: [NoxDiscoveredNode]) -> String {
        nodes
            .sorted { $0.deviceId < $1.deviceId }
            .map { node in
                [
                    node.deviceId,
                    node.deviceName,
                    node.state.rawValue,
                    node.presenceToken,
                    node.hostName ?? "",
                    "\(node.pairingPort)",
                    node.appleModel ?? "",
                    node.appleDeviceIdentifier ?? "",
                    node.appleGroupIdentifier ?? "",
                    node.appleGroupName ?? "",
                    node.appleGroupMemberNames.joined(separator: ","),
                ].joined(separator: "|")
            }
            .joined(separator: "\n")
    }

    private func emitAmbient(_ event: NoxMeshAmbientEvent) {
        lastAmbientEvent = event
    }

    func consumeAmbientEvent() {
        lastAmbientEvent = nil
    }
}

nonisolated enum NoxMeshAmbientEvent: Equatable, Sendable {
    case trustEstablished(deviceName: String)
    case pulseReceived(deviceName: String)
    case pulseSentConfirmed(deviceName: String)
    case presenceExpanded
}
