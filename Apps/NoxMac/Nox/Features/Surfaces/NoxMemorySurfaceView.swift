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

struct NoxMemorySurfaceView: View {
    @Environment(AppEnvironment.self) private var environment

    private var ownership: NoxMemoryEcologyOwnership {
        environment.memoryEcologyOwnership
    }

    private var isDeepReflection: Bool {
        environment.preferences.windowMode == .deepReflection
    }

    private var orbitItems: [NoxMemoryOrbitItem] {
        NoxMemoryEcologyPresenter.orbitItems(
            nearbyNodes: environment.presenceMesh.ambientNearbyNodes,
            trustedNodes: environment.presenceMesh.trustedNodes,
            resolveKind: { NoxPresenceCurator.resolvedDeviceKind(for: $0) },
            resolveKindName: { NoxPresenceCurator.resolvedDeviceKind(for: $0) },
            hasConfiguredStation: environment.presenceMesh.hasConfiguredNoxStation
        )
    }

    private var eraObservation: String? {
        NoxTemporalMemoryRowPresenter.eraObservation(for: environment.memoryEvolutionSnapshot)
    }

    var body: some View {
        NoxSurfacePage {
            if !ownership.exposesFullMemoryBrowser {
                NoxMemoryBeaconEcologyGate()
            } else {
                memoryBrowser
            }
        }
    }

    @ViewBuilder
    private var memoryBrowser: some View {
        if ownership.primaryLayer != .orbit {
            NoxMemoryPeriodPicker()
            NoxMemorySearchField()
        }

        let layerSpacing = isDeepReflection ? NoxSpacing.section : NoxSpacing.xl

        VStack(alignment: .leading, spacing: layerSpacing) {
            ecologyContent
        }
    }

    @ViewBuilder
    private var ecologyContent: some View {
        switch ownership.primaryLayer {
        case .galaxy:
            separatedNoxIContent
        case .deepSpace:
            if ownership.deviceRole == .station {
                stationArchiveContent
            } else {
                unifiedOrArchivalDeepSpaceContent
            }
        case .orbit:
            satelliteOrbitContent
        }
    }

    @ViewBuilder
    private var separatedNoxIContent: some View {
        if ownership.showsGalaxySection {
            NoxMemoryGalaxySection(
                ownership: ownership,
                sections: environment.galaxyTimelineSections,
                emergence: environment.galaxyEmergence,
                dayOverview: environment.galaxyDayOverview,
                eraObservation: eraObservation,
                isDeepReflection: isDeepReflection
            )
        }
        if ownership.showsOrbitSection {
            NoxMemoryOrbitSection(ownership: ownership, items: orbitItems)
        }
        if ownership.showsDeepSpaceSection {
            NoxMemoryDeepSpaceSection(
                ownership: ownership,
                period: environment.memoryPeriod,
                timelineSections: environment.deepSpaceTimelineSections,
                archivalEntries: environment.deepSpaceEntries,
                isDeepReflection: isDeepReflection
            )
        }
    }

    @ViewBuilder
    private var unifiedOrArchivalDeepSpaceContent: some View {
        if ownership.showsDeepSpaceSection {
            NoxMemoryDeepSpaceSection(
                ownership: ownership,
                period: environment.memoryPeriod,
                timelineSections: environment.deepSpaceTimelineSections,
                archivalEntries: environment.deepSpaceEntries,
                isDeepReflection: isDeepReflection,
                activeTimelineSections: environment.galaxyTimelineSections,
                dayOverview: environment.galaxyDayOverview,
                eraObservation: eraObservation,
                emergence: environment.galaxyEmergence
            )
        }
        if ownership.showsOrbitSection {
            NoxMemoryOrbitSection(ownership: ownership, items: orbitItems)
        }
    }

    @ViewBuilder
    private var stationArchiveContent: some View {
        NoxMemoryDeepSpaceSection(
            ownership: ownership,
            period: environment.memoryPeriod,
            timelineSections: environment.deepSpaceTimelineSections,
            archivalEntries: environment.deepSpaceEntries,
            isDeepReflection: isDeepReflection
        )
    }

    @ViewBuilder
    private var satelliteOrbitContent: some View {
        NoxMemoryOrbitSection(ownership: ownership, items: orbitItems)
    }
}
