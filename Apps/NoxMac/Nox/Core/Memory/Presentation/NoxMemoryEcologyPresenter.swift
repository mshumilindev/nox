import Foundation
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

/// Routes loaded memory into Galaxy / Orbit / Deep Space presentation slices.
enum NoxMemoryEcologyPresenter {

    static func orbitItems(
        nearbyNodes: [NoxDiscoveredNode],
        trustedNodes: [NoxTrustedNode],
        resolveKind: (NoxDiscoveredNode) -> NoxPresenceDeviceKind?,
        resolveKindName: (String) -> NoxPresenceDeviceKind?,
        hasConfiguredStation: Bool
    ) -> [NoxMemoryOrbitItem] {
        var items: [NoxMemoryOrbitItem] = []
        let context = NoxConstellationClassificationContext(hasConfiguredStation: hasConfiguredStation)

        for node in nearbyNodes {
            guard let kind = resolveKind(node) else { continue }
            let presentation = NoxConstellationRoleResolver.nearbyCandidatePresentation(
                for: node,
                kind: kind,
                isGroupedHomePodStereo: node.appleGroupMemberNames.count > 1 && kind == .homePod,
                context: context
            )
            guard presentation.roleLabel.contains("Satellite") || presentation.roleLabel.contains("Beacon") else {
                continue
            }
            items.append(
                NoxMemoryOrbitItem(
                    id: "orbit-\(node.deviceId)",
                    deviceName: node.deviceName,
                    roleLine: presentation.roleLabel,
                    detail: orbitDetailLine(for: kind, metadata: presentation.metadata),
                    isBeaconClass: kind == .homePod
                )
            )
        }

        for trusted in trustedNodes {
            guard trusted.constellationRole == .satellite || trusted.constellationRole == .beacon else {
                continue
            }
            let kind = resolveKindName(trusted.trustedDeviceName) ?? .iPhone
            let role = trusted.constellationRole.map {
                NoxConstellationRoleResolver.assignedRoleLabel($0)
            } ?? "Nox Satellite"
            items.append(
                NoxMemoryOrbitItem(
                    id: "orbit-trusted-\(trusted.trustedNodeId)",
                    deviceName: trusted.trustedDeviceName,
                    roleLine: role,
                    detail: "Orbit memory from a trusted device",
                    isBeaconClass: trusted.constellationRole == .beacon
                )
            )
        }

        return items
    }

    static func deepSpaceEntries(
        longHorizon: NoxLongHorizonSnapshot,
        evolution: NoxMemoryEvolutionSnapshot
    ) -> [NoxMemoryDeepSpaceEntry] {
        var entries: [NoxMemoryDeepSpaceEntry] = []
        var index = 0

        func append(_ title: String, _ detail: String? = nil) {
            entries.append(NoxMemoryDeepSpaceEntry(id: "ds-\(index)", title: title, detail: detail))
            index += 1
        }

        for note in longHorizon.resurfacingNotes {
            append(note)
        }
        for narrative in longHorizon.longHorizonNarratives {
            append(narrative.summary, narrative.horizonLabel)
        }
        for structure in evolution.longHorizonStructures {
            append(structure)
        }
        for insight in evolution.identityInsights {
            append(insight.line)
        }
        for note in evolution.longTermResurfacingNotes {
            append(note)
        }
        if let coherence = evolution.temporalCoherenceLine, !coherence.isEmpty {
            append(coherence)
        }
        for pattern in longHorizon.emergingPatterns.prefix(4) {
            append(pattern.title, pattern.detail)
        }

        return entries
    }

    private static func orbitDetailLine(
        for kind: NoxPresenceDeviceKind,
        metadata: String?
    ) -> String {
        if let metadata, !metadata.isEmpty {
            return "Orbit memory awaiting transfer · \(metadata)"
        }
        switch kind {
        case .homePod:
            return "Beacon signal — peripheral context awaiting Nox I"
        case .appleWatch:
            return "Watch continuity fragment awaiting transfer"
        case .iPhone, .iPad:
            return "Orbit memory awaiting transfer to Nox I"
        case .appleTV:
            return "Ambient surface context awaiting transfer"
        default:
            return "Temporary device memory awaiting Nox I"
        }
    }
}
