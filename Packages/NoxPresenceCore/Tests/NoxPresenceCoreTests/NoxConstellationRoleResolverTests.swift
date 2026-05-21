import Foundation
import NoxPresenceCore
import Testing

struct NoxConstellationRoleResolverTests {

    private let noStation = NoxConstellationClassificationContext(hasConfiguredStation: false)
    private let withStation = NoxConstellationClassificationContext(hasConfiguredStation: true)

    @Test func nearbyMacBookWithoutStationIsSatelliteCandidate() {
        let node = appleNode(id: "apple-macbook", name: "Studio MacBook Pro", kind: .macBookPro)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .macBookPro,
            isGroupedHomePodStereo: false,
            context: noStation
        )
        #expect(presentation.roleLabel == "Potential Nox Satellite")
        #expect(presentation.metadata == nil)
    }

    @Test func nearbyHomePodIsBeaconCandidate() {
        let node = appleNode(id: "apple-homepod-1", name: "Kitchen", kind: .homePod)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .homePod,
            isGroupedHomePodStereo: false,
            context: noStation
        )
        #expect(presentation.roleLabel == "Potential Nox Beacon")
    }

    @Test func nearbyHomePodStereoShowsBeaconRoleAndMetadata() {
        let node = appleNode(id: "apple-homepod-group", name: "Living room", kind: .homePod)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .homePod,
            isGroupedHomePodStereo: true,
            context: noStation
        )
        #expect(presentation.roleLabel == "Potential Nox Beacon")
        #expect(presentation.metadata == "Stereo pair nearby")
    }

    @Test func nearbyAppleTVIsSatelliteNotBeacon() {
        let node = appleNode(id: "apple-appletv-1", name: "Вітальня", kind: .appleTV)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .appleTV,
            isGroupedHomePodStereo: false,
            context: noStation
        )
        #expect(presentation.roleLabel == "Potential Nox Satellite")
    }

    @Test func nearbyIMacWithoutStationIsStationCandidate() {
        let node = appleNode(id: "apple-imac-1", name: "iMac — Mykola", kind: .iMac)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .iMac,
            isGroupedHomePodStereo: false,
            context: noStation
        )
        #expect(presentation.roleLabel == "Potential Nox Station")
    }

    @Test func nearbyIMacWithStationConfiguredIsSatelliteCandidate() {
        let node = appleNode(id: "apple-imac-1", name: "iMac — Mykola", kind: .iMac)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .iMac,
            isGroupedHomePodStereo: false,
            context: withStation
        )
        #expect(presentation.roleLabel == "Potential Nox Satellite")
    }

    @Test func nearbyNoxPeerShowsExpansionCopy() {
        let node = NoxDiscoveredNode(
            deviceId: UUID().uuidString,
            deviceName: "Mykola's MacBook Pro",
            protocolVersion: 1,
            publicKeyFingerprint: "a1b2c3d4e5f6",
            presenceToken: "tok",
            pairingPort: 9121,
            state: .nearby,
            lastSeenAt: Date()
        )
        #expect(NoxConstellationRoleResolver.isNoxMeshPeer(node))
        #expect(
            NoxConstellationRoleResolver.nearbyCandidatePresentation(
                for: node,
                kind: .macBookPro,
                isGroupedHomePodStereo: false,
                context: noStation
            ).roleLabel == "Available for constellation expansion"
        )
    }

    @Test func nearbyIPhoneIsSatelliteCandidate() {
        let node = appleNode(id: "apple-iphone-1", name: "Nearby iPhone", kind: .iPhone)
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .iPhone,
            isGroupedHomePodStereo: false,
            context: noStation
        )
        #expect(presentation.roleLabel == "Potential Nox Satellite")
    }

    @Test func explicitAssignedRoleOverridesLadder() {
        let node = appleNode(id: "apple-imac-1", name: "iMac — Mykola", kind: .iMac)
        let context = NoxConstellationClassificationContext(
            hasConfiguredStation: false,
            explicitAssignedRole: .beacon
        )
        let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
            for: node,
            kind: .iMac,
            isGroupedHomePodStereo: false,
            context: context
        )
        #expect(presentation.roleLabel == "Nox Beacon")
    }

    @Test func hasConfiguredStationRequiresExplicitRoleOnTrustedNode() {
        let trusted = NoxTrustedNode(
            trustedNodeId: "id",
            trustedDeviceName: "Desk iMac",
            publicKeyFingerprint: "fp",
            publicKeyBase64: "key",
            trustCreatedAt: Date(),
            lastSeenAt: Date(),
            systemId: "sys",
            protocolVersion: 1,
            constellationRole: .station
        )
        #expect(NoxConstellationRoleResolver.hasConfiguredStation(in: [trusted]))
        #expect(!NoxConstellationRoleResolver.hasConfiguredStation(in: []))
    }

    @Test func currentDeviceCopyUsesNoxIOwnershipLanguage() {
        #expect(NoxConstellationCopy.currentDeviceSubtitle(isNoxIActive: true) == "This is your Nox I")
        #expect(NoxConstellationCopy.currentDeviceDetail(isNoxIActive: true) == "This device anchors your constellation")
    }

    private func appleNode(
        id: String,
        name: String,
        kind: NoxPresenceDeviceKind
    ) -> NoxDiscoveredNode {
        NoxDiscoveredNode(
            deviceId: id,
            deviceName: name,
            protocolVersion: 1,
            publicKeyFingerprint: "",
            presenceToken: "apple-presence:\(kind.rawValue)",
            pairingPort: 0,
            state: .unavailable,
            lastSeenAt: Date()
        )
    }
}
