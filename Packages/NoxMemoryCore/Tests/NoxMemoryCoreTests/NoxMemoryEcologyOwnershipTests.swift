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
        #expect(ownership.chromeSubtitle == "Active memory on Nox I")
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
        #expect(ownership.chromeSubtitle == "Historical memory archive")
        #expect(!ownership.showsGalaxySection)
        #expect(ownership.externalLayerNote?.contains("Nox I") == true)
    }

    @Test func satelliteUsesOrbitPrimary() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .satellite,
            hasConfiguredStation: true
        )
        #expect(ownership.navigationTitle == "Orbit")
        #expect(ownership.primaryLayer == .orbit)
        #expect(!ownership.showsDeepSpaceSection)
    }

    @Test func beaconDoesNotExposeMemoryBrowser() {
        let ownership = NoxMemoryEcologyOwnershipResolver.resolve(
            currentDeviceRole: .beacon,
            hasConfiguredStation: false
        )
        #expect(!ownership.exposesFullMemoryBrowser)
    }
}
