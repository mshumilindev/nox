import Foundation
import NoxPresenceCore
import Testing

struct NoxConstellationRoleIconsTests {

    @Test func assignedRoleSymbols() {
        #expect(NoxConstellationRoleIcons.symbol(for: .noxI) == "circle.hexagongrid.fill")
        #expect(NoxConstellationRoleIcons.symbol(for: .station) == "internaldrive")
        #expect(NoxConstellationRoleIcons.symbol(for: .satellite) == "point.3.connected.trianglepath.dotted")
    }

    @Test func candidateLabelMapsToRoleIcon() {
        #expect(
            NoxConstellationRoleIcons.symbolForRoleLabel("Potential Nox Beacon")
                == NoxConstellationRoleIcons.beaconPrimary
        )
        #expect(
            NoxConstellationRoleIcons.symbolForRoleLabel("Potential Nox Station")
                == NoxConstellationRoleIcons.stationPrimary
        )
        #expect(
            NoxConstellationRoleIcons.symbolForRoleLabel("Potential Nox Satellite")
                == NoxConstellationRoleIcons.satellitePrimary
        )
    }
}
