import Foundation
import NoxMemoryCore
import Testing

struct NoxMemoryEcologyOwnershipTests {

    @Test func noxIWithoutStationUsesDeepSpacePrimary() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .noxI,
            hasConfiguredStation: false
        )
        #expect(ownership.navigationTitle == "Deep Space")
        #expect(ownership.navigationSecondaryHint == "Historical + active memory")
        #expect(ownership.navigationSymbolName == NoxMemoryEcologyIcons.deepSpacePrimary)
        #expect(ownership.showsInNavigation)
        #expect(ownership.chromeSubtitle == "Historical and active memory on Nox I")
        #expect(ownership.primaryLayer == .deepSpace)
        #expect(!ownership.ecologyIsSeparated)
        #expect(!ownership.showsGalaxySection)
        #expect(ownership.showsDeepSpaceSection)
    }

    @Test func noxIWithStationUsesGalaxyPrimary() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .noxI,
            hasConfiguredStation: true
        )
        #expect(ownership.navigationTitle == "Galaxy")
        #expect(ownership.navigationSecondaryHint == "Active memory")
        #expect(ownership.navigationSymbolName == NoxMemoryEcologyIcons.galaxyPrimary)
        #expect(ownership.primaryLayer == .galaxy)
        #expect(ownership.ecologyIsSeparated)
        #expect(ownership.showsGalaxySection)
        #expect(ownership.deepSpaceResidencyLine?.contains("Nox Station") == true)
    }

    @Test func stationUsesDeepSpaceArchive() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .station,
            hasConfiguredStation: true
        )
        #expect(ownership.navigationTitle == "Deep Space")
        #expect(ownership.navigationSecondaryHint == "Historical archive")
        #expect(ownership.navigationSymbolName == NoxMemoryEcologyIcons.deepSpacePrimary)
        #expect(!ownership.showsGalaxySection)
        #expect(ownership.externalLayerNote?.contains("Nox I") == true)
    }

    @Test func satelliteUsesOrbitPrimary() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .satellite,
            hasConfiguredStation: true
        )
        #expect(ownership.navigationTitle == "Orbit")
        #expect(ownership.navigationSecondaryHint == "Temporary memory")
        #expect(ownership.navigationSymbolName == NoxMemoryEcologyIcons.orbitPrimary)
        #expect(ownership.primaryLayer == .orbit)
        #expect(!ownership.showsDeepSpaceSection)
    }

    @Test func beaconHiddenFromNavigation() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .beacon,
            hasConfiguredStation: false
        )
        #expect(!ownership.exposesFullMemoryBrowser)
        #expect(!ownership.showsInNavigation)
    }
}

struct NoxMemoryEcologyIconsTests {

    @Test func layerSymbolsAreDistinct() {
        let galaxy = NoxMemoryEcologyIcons.symbol(for: .galaxy)
        let orbit = NoxMemoryEcologyIcons.symbol(for: .orbit)
        let deep = NoxMemoryEcologyIcons.symbol(for: .deepSpace)
        #expect(galaxy == "sparkles")
        #expect(orbit == "point.3.connected.trianglepath.dotted")
        #expect(deep == "archivebox.fill")
        #expect(Set([galaxy, orbit, deep]).count == 3)
    }
}
