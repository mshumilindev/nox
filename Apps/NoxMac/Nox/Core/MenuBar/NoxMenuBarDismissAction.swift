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

private struct NoxMenuBarDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var noxMenuBarDismiss: (() -> Void)? {
        get { self[NoxMenuBarDismissKey.self] }
        set { self[NoxMenuBarDismissKey.self] = newValue }
    }
}
