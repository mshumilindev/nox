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

@MainActor
enum NoxAppRuntime {
    static let environment = AppEnvironment()
    static let panelState = NoxPanelState()
    static let statusBar = NoxStatusBarController()
    static let presenceMesh = PresenceMeshManager()
}
