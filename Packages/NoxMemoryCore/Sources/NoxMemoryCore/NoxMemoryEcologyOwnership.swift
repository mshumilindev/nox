import Foundation

/// Role of the device running the memory surface (not a trusted peer).
public enum NoxMemoryEcologyDeviceRole: String, Sendable, Equatable, Codable {
    case noxI
    case station
    case satellite
    case beacon
}

/// Canonical ecology layer used for navigation and primary surface identity.
public enum NoxMemoryEcologyPrimaryLayer: String, Sendable, Equatable, Codable {
    case galaxy
    case orbit
    case deepSpace
}

/// Dynamic memory ecology ownership — navigation, chrome, and section visibility.
public struct NoxMemoryEcologyOwnership: Sendable, Equatable {
    public let deviceRole: NoxMemoryEcologyDeviceRole
    public let hasConfiguredStation: Bool
    public let primaryLayer: NoxMemoryEcologyPrimaryLayer
    public let navigationTitle: String
    /// Short ecology hint under the rail label (~11–12pt).
    public let navigationSecondaryHint: String
    public let navigationSymbolName: String
    public let showsInNavigation: Bool
    public let chromeSubtitle: String
    /// Galaxy exists as a distinct visible layer (requires Station externalization).
    public let ecologyIsSeparated: Bool
    public let showsGalaxySection: Bool
    public let showsOrbitSection: Bool
    public let showsDeepSpaceSection: Bool
    public let exposesFullMemoryBrowser: Bool
    public let deepSpaceSectionSubtitle: String
    public let galaxySectionSubtitle: String
    public let orbitSectionSubtitle: String
    /// Context line under Deep Space when archival lives elsewhere or is unified on Nox I.
    public let deepSpaceResidencyLine: String?
    /// Shown when Galaxy / Deep Space are external (Station / Satellite).
    public let externalLayerNote: String?

    public init(
        deviceRole: NoxMemoryEcologyDeviceRole,
        hasConfiguredStation: Bool,
        primaryLayer: NoxMemoryEcologyPrimaryLayer,
        navigationTitle: String,
        navigationSecondaryHint: String,
        navigationSymbolName: String,
        showsInNavigation: Bool,
        chromeSubtitle: String,
        ecologyIsSeparated: Bool,
        showsGalaxySection: Bool,
        showsOrbitSection: Bool,
        showsDeepSpaceSection: Bool,
        exposesFullMemoryBrowser: Bool,
        deepSpaceSectionSubtitle: String,
        galaxySectionSubtitle: String,
        orbitSectionSubtitle: String,
        deepSpaceResidencyLine: String?,
        externalLayerNote: String?
    ) {
        self.deviceRole = deviceRole
        self.hasConfiguredStation = hasConfiguredStation
        self.primaryLayer = primaryLayer
        self.navigationTitle = navigationTitle
        self.navigationSecondaryHint = navigationSecondaryHint
        self.navigationSymbolName = navigationSymbolName
        self.showsInNavigation = showsInNavigation
        self.chromeSubtitle = chromeSubtitle
        self.ecologyIsSeparated = ecologyIsSeparated
        self.showsGalaxySection = showsGalaxySection
        self.showsOrbitSection = showsOrbitSection
        self.showsDeepSpaceSection = showsDeepSpaceSection
        self.exposesFullMemoryBrowser = exposesFullMemoryBrowser
        self.deepSpaceSectionSubtitle = deepSpaceSectionSubtitle
        self.galaxySectionSubtitle = galaxySectionSubtitle
        self.orbitSectionSubtitle = orbitSectionSubtitle
        self.deepSpaceResidencyLine = deepSpaceResidencyLine
        self.externalLayerNote = externalLayerNote
    }
}

/// Resolves role- and station-dependent memory ecology presentation.
public enum NoxMemoryEcologyOwnershipResolver {
    public static let galaxyName = "Galaxy"
    public static let orbitName = "Orbit"
    public static let deepSpaceName = "Deep Space"

    public static func resolve(
        currentDeviceRole: NoxMemoryEcologyDeviceRole,
        hasConfiguredStation: Bool
    ) -> NoxMemoryEcologyOwnership {
        switch currentDeviceRole {
        case .beacon:
            return NoxMemoryEcologyOwnership(
                deviceRole: .beacon,
                hasConfiguredStation: hasConfiguredStation,
                primaryLayer: .orbit,
                navigationTitle: orbitName,
                navigationSecondaryHint: "",
                navigationSymbolName: NoxMemoryEcologyIcons.symbol(for: .orbit),
                showsInNavigation: false,
                chromeSubtitle: "Ambient beacon",
                ecologyIsSeparated: false,
                showsGalaxySection: false,
                showsOrbitSection: false,
                showsDeepSpaceSection: false,
                exposesFullMemoryBrowser: false,
                deepSpaceSectionSubtitle: "",
                galaxySectionSubtitle: "",
                orbitSectionSubtitle: "",
                deepSpaceResidencyLine: nil,
                externalLayerNote: nil
            )

        case .satellite:
            return NoxMemoryEcologyOwnership(
                deviceRole: .satellite,
                hasConfiguredStation: hasConfiguredStation,
                primaryLayer: .orbit,
                navigationTitle: orbitName,
                navigationSecondaryHint: "Temporary memory",
                navigationSymbolName: NoxMemoryEcologyIcons.symbol(for: .orbit),
                showsInNavigation: true,
                chromeSubtitle: "Temporary device memory",
                ecologyIsSeparated: false,
                showsGalaxySection: false,
                showsOrbitSection: true,
                showsDeepSpaceSection: false,
                exposesFullMemoryBrowser: true,
                deepSpaceSectionSubtitle: "",
                galaxySectionSubtitle: "",
                orbitSectionSubtitle: "Temporary device memory",
                deepSpaceResidencyLine: nil,
                externalLayerNote: "Galaxy and Deep Space live on other devices in your constellation."
            )

        case .station:
            return NoxMemoryEcologyOwnership(
                deviceRole: .station,
                hasConfiguredStation: true,
                primaryLayer: .deepSpace,
                navigationTitle: deepSpaceName,
                navigationSecondaryHint: "Historical archive",
                navigationSymbolName: NoxMemoryEcologyIcons.symbol(for: .deepSpace),
                showsInNavigation: true,
                chromeSubtitle: "Historical memory archive",
                ecologyIsSeparated: true,
                showsGalaxySection: false,
                showsOrbitSection: false,
                showsDeepSpaceSection: true,
                exposesFullMemoryBrowser: true,
                deepSpaceSectionSubtitle: "Historical memory archive",
                galaxySectionSubtitle: "",
                orbitSectionSubtitle: "",
                deepSpaceResidencyLine: nil,
                externalLayerNote: "Living memory is on Nox I."
            )

        case .noxI:
            if hasConfiguredStation {
                return NoxMemoryEcologyOwnership(
                    deviceRole: .noxI,
                    hasConfiguredStation: true,
                    primaryLayer: .galaxy,
                    navigationTitle: galaxyName,
                    navigationSecondaryHint: "Active memory",
                    navigationSymbolName: NoxMemoryEcologyIcons.symbol(for: .galaxy),
                    showsInNavigation: true,
                    chromeSubtitle: "Active memory on Nox I",
                    ecologyIsSeparated: true,
                    showsGalaxySection: true,
                    showsOrbitSection: true,
                    showsDeepSpaceSection: true,
                    exposesFullMemoryBrowser: true,
                    deepSpaceSectionSubtitle: "Archival and long-horizon continuity",
                    galaxySectionSubtitle: "Active memory on Nox I",
                    orbitSectionSubtitle: "Temporary Satellite and Beacon memory",
                    deepSpaceResidencyLine: "Deep Space is stored on your Nox Station.",
                    externalLayerNote: nil
                )
            }
            return NoxMemoryEcologyOwnership(
                deviceRole: .noxI,
                hasConfiguredStation: false,
                primaryLayer: .deepSpace,
                navigationTitle: deepSpaceName,
                navigationSecondaryHint: "Historical + active memory",
                navigationSymbolName: NoxMemoryEcologyIcons.symbol(for: .deepSpace),
                showsInNavigation: true,
                chromeSubtitle: "Historical and active memory on Nox I",
                ecologyIsSeparated: false,
                showsGalaxySection: false,
                showsOrbitSection: true,
                showsDeepSpaceSection: true,
                exposesFullMemoryBrowser: true,
                deepSpaceSectionSubtitle: "Historical and active memory on Nox I",
                galaxySectionSubtitle: "",
                orbitSectionSubtitle: "Temporary Satellite and Beacon memory",
                deepSpaceResidencyLine: "Nox I currently stores both active and historical memory.",
                externalLayerNote: nil
            )
        }
    }
}
