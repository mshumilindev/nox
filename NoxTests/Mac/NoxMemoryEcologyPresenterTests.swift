import Foundation
import NoxMemoryCore
import NoxPresenceCore
import Testing
@testable import Nox

struct NoxMemoryEcologyPresenterTests {

    @Test func orbitEmptyWithoutSatelliteOrBeaconPeers() {
        let items = NoxMemoryEcologyPresenter.orbitItems(
            nearbyNodes: [],
            trustedNodes: [],
            resolveKind: { _ in .iPhone },
            resolveKindName: { _ in .iPhone },
            hasConfiguredStation: false
        )
        #expect(items.isEmpty)
    }

    @Test func orbitIncludesTrustedSatellite() {
        let trusted = NoxTrustedNode(
            trustedNodeId: "t1",
            trustedDeviceName: "My iPhone",
            publicKeyFingerprint: "fp",
            publicKeyBase64: "key",
            trustCreatedAt: Date(),
            lastSeenAt: Date(),
            systemId: "sys",
            protocolVersion: 1,
            constellationRole: .satellite
        )
        let items = NoxMemoryEcologyPresenter.orbitItems(
            nearbyNodes: [],
            trustedNodes: [trusted],
            resolveKind: { _ in .iPhone },
            resolveKindName: { _ in .iPhone },
            hasConfiguredStation: false
        )
        #expect(items.count == 1)
        #expect(items[0].deviceName == "My iPhone")
        #expect(items[0].detail.contains("trusted"))
    }

    @Test func deepSpaceEntriesPullFromLongHorizonAndEvolution() {
        let horizon = NoxLongHorizonSnapshot(
            activeThreads: [],
            emergingPatterns: [],
            recentContinuities: [],
            longHorizonNarratives: [],
            behavioralRhythms: [],
            eraCandidates: [],
            semanticArcs: [],
            reflections: [],
            resurfacingNotes: ["Older note resurfacing"],
            connectorCadencePatterns: [],
            connectorEnrichmentNotes: [],
            behavioralSignatures: [],
            temporalRhythmInsights: [],
            lifeStructureCandidates: [],
            behavioralDrift: nil,
            memoryEvolution: .neutral
        )
        let evolution = NoxMemoryEvolutionSnapshot(
            agingProfiles: [],
            longHorizonStructures: ["Compressed era structure"],
            identityInsights: [],
            eraHints: [],
            unresolvedSignals: [],
            ecologyNotes: [],
            temporalWeights: [:],
            resilienceScores: [:],
            longTermResurfacingNotes: [],
            temporalCoherenceLine: nil,
            prioritizedThreadIds: [],
            prioritizedArcIds: [],
            preferSparseSurfaces: false
        )
        let entries = NoxMemoryEcologyPresenter.deepSpaceEntries(
            longHorizon: horizon,
            evolution: evolution
        )
        #expect(entries.contains { $0.title == "Older note resurfacing" })
        #expect(entries.contains { $0.title == "Compressed era structure" })
    }
}
