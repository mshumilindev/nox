import Foundation

/// Assigned constellation role — only when explicitly configured (not inferred for trusted peers).
public enum NoxConstellationAssignedRole: String, Sendable, Codable {
    case noxI
    case station
    case satellite
    case beacon
}

/// Inputs for strict role-ladder classification (no heuristics beyond device kind + station config).
public struct NoxConstellationClassificationContext: Sendable, Equatable {
    public var hasConfiguredStation: Bool
    public var explicitAssignedRole: NoxConstellationAssignedRole?

    public init(
        hasConfiguredStation: Bool,
        explicitAssignedRole: NoxConstellationAssignedRole? = nil
    ) {
        self.hasConfiguredStation = hasConfiguredStation
        self.explicitAssignedRole = explicitAssignedRole
    }
}

/// Role line plus optional metadata (e.g. stereo pair) for constellation device cards.
public struct NoxConstellationCandidatePresentation: Equatable, Sendable {
    public let roleLabel: String
    public let metadata: String?

    public init(roleLabel: String, metadata: String? = nil) {
        self.roleLabel = roleLabel
        self.metadata = metadata
    }
}

/// Canonical copy and strict role labeling for the Constellation device ecosystem surface.
public enum NoxConstellationCopy {
    public static let pageTitle = "Constellation"
    public static let pageSubtitle = "Devices around your life that may join Nox."

    public static let sectionCurrentDevice = "Current device"
    public static let sectionNearbyCandidates = "Nearby constellation candidates"
    public static let sectionTrustedDevices = "Trusted constellation devices"
    public static let sectionExpandActions = "Expand Nox"

    public static let emptyNearbyTitle = "No constellation candidates yet."
    public static let emptyNearbyDetail = "Listening for nearby devices on this network."
    public static let emptyTrustedHint = "Approved devices will appear here."
    public static let listeningOverlayTitle = "Listening for your constellation…"
    public static let listeningOverlayDetail = "Searching for nearby devices on this network."

    public static let expandSheetTitle = "Expand constellation"
    public static let expandSheetClose = "Close"
    public static let beginExpansion = "Begin expansion"
    public static let inviteDevice = "Invite to constellation"
    public static let copySetupLink = "Copy setup link"

    public static let stereoPairNearby = "Stereo pair nearby"
    public static let potentialBeacon = "Potential Nox Beacon"
    public static let potentialStation = "Potential Nox Station"
    public static let potentialSatellite = "Potential Nox Satellite"
    public static let availableForExpansion = "Available for constellation expansion"

    public static let currentDeviceNoxI = "This is your Nox I"
    public static let currentDeviceAnchor = "This device anchors your constellation"
    public static let currentDeviceGeneric = "Part of your constellation"

    public static func currentDeviceSubtitle(isNoxIActive: Bool) -> String {
        isNoxIActive ? currentDeviceNoxI : currentDeviceGeneric
    }

    public static func currentDeviceDetail(isNoxIActive: Bool) -> String? {
        isNoxIActive ? currentDeviceAnchor : nil
    }

    public static func trustedSubtitle(assignedRole: NoxConstellationAssignedRole?) -> String {
        guard let assignedRole else {
            return "Trusted in your constellation"
        }
        return NoxConstellationRoleResolver.assignedRoleLabel(assignedRole)
    }

    public static func approvalSubtitle(for kind: NoxPresenceDeviceKind) -> String {
        "Waiting to join your constellation"
    }
}

/// Strict device-role ladder for Constellation discovery UI.
public enum NoxConstellationRoleResolver {
    public static func isNoxIActiveOnThisDevice(isMacOSCanonicalApp: Bool) -> Bool {
        isMacOSCanonicalApp
    }

    public static func hasConfiguredStation(in trustedNodes: [NoxTrustedNode]) -> Bool {
        trustedNodes.contains { $0.constellationRole == .station }
    }

    public static func isNoxMeshPeer(_ node: NoxDiscoveredNode) -> Bool {
        guard node.state != .unavailable else { return false }
        guard !node.deviceId.hasPrefix("apple-") else { return false }
        return NoxPresenceCurator.isPresentableNoxEnvironment(node)
    }

    public static func isPassiveBeaconHardware(_ kind: NoxPresenceDeviceKind) -> Bool {
        kind == .homePod
    }

    public static func isStationEligibleDesktop(_ kind: NoxPresenceDeviceKind) -> Bool {
        switch kind {
        case .iMac, .macStudio, .macMini, .mac:
            return true
        case .macBookPro, .macBookAir, .iPhone, .iPad, .appleWatch, .appleTV, .homePod:
            return false
        }
    }

    public static func assignedRoleLabel(_ role: NoxConstellationAssignedRole) -> String {
        switch role {
        case .noxI: "Nox I"
        case .station: "Nox Station"
        case .satellite: "Nox Satellite"
        case .beacon: "Nox Beacon"
        }
    }

    /// Classify through the canonical ladder (explicit role → beacon → station → satellite).
    public static func nearbyCandidatePresentation(
        for node: NoxDiscoveredNode,
        kind: NoxPresenceDeviceKind,
        isGroupedHomePodStereo: Bool,
        context: NoxConstellationClassificationContext
    ) -> NoxConstellationCandidatePresentation {
        if let explicit = context.explicitAssignedRole {
            return NoxConstellationCandidatePresentation(
                roleLabel: assignedRoleLabel(explicit),
                metadata: nil
            )
        }

        if isNoxMeshPeer(node) {
            return NoxConstellationCandidatePresentation(
                roleLabel: NoxConstellationCopy.availableForExpansion,
                metadata: nil
            )
        }

        if isPassiveBeaconHardware(kind) {
            let metadata = isGroupedHomePodStereo ? NoxConstellationCopy.stereoPairNearby : nil
            return NoxConstellationCandidatePresentation(
                roleLabel: NoxConstellationCopy.potentialBeacon,
                metadata: metadata
            )
        }

        if !context.hasConfiguredStation, isStationEligibleDesktop(kind) {
            return NoxConstellationCandidatePresentation(
                roleLabel: NoxConstellationCopy.potentialStation,
                metadata: nil
            )
        }

        return NoxConstellationCandidatePresentation(
            roleLabel: NoxConstellationCopy.potentialSatellite,
            metadata: nil
        )
    }

    public static func nearbyCandidateLabel(
        for node: NoxDiscoveredNode,
        kind: NoxPresenceDeviceKind,
        isGroupedHomePodStereo: Bool = false,
        context: NoxConstellationClassificationContext = NoxConstellationClassificationContext(hasConfiguredStation: false)
    ) -> String {
        nearbyCandidatePresentation(
            for: node,
            kind: kind,
            isGroupedHomePodStereo: isGroupedHomePodStereo,
            context: context
        ).roleLabel
    }

    public static func contextLine(for tone: NoxPresenceCardTone) -> String {
        switch tone {
        case .nearby:
            "Nearby constellation candidate"
        case .unavailable:
            "Constellation candidate"
        case .awaitingTrust:
            "Ready to join your constellation"
        case .trusted:
            "Part of your constellation"
        case .expanding:
            "Expanding your constellation…"
        }
    }

    public static func defaultCardSubtitle(
        for kind: NoxPresenceDeviceKind,
        tone: NoxPresenceCardTone,
        node: NoxDiscoveredNode? = nil,
        isGroupedHomePodStereo: Bool = false,
        context: NoxConstellationClassificationContext = NoxConstellationClassificationContext(hasConfiguredStation: false)
    ) -> String {
        if let node, tone == .unavailable || tone == .nearby {
            return nearbyCandidatePresentation(
                for: node,
                kind: kind,
                isGroupedHomePodStereo: isGroupedHomePodStereo,
                context: context
            ).roleLabel
        }
        switch tone {
        case .nearby:
            return NoxConstellationCopy.availableForExpansion
        case .unavailable:
            if isPassiveBeaconHardware(kind) {
                return NoxConstellationCopy.potentialBeacon
            }
            if !context.hasConfiguredStation, isStationEligibleDesktop(kind) {
                return NoxConstellationCopy.potentialStation
            }
            return NoxConstellationCopy.potentialSatellite
        case .awaitingTrust:
            return NoxConstellationCopy.approvalSubtitle(for: kind)
        case .trusted:
            return "Trusted in your constellation"
        case .expanding:
            return "Connecting…"
        }
    }
}
