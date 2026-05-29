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
import NoxShrineCore

/// Legacy entry — ambient shell is the primary surface.
struct NoxDashboardView: View {
    var body: some View {
        NoxAmbientShellView()
    }
}

#Preview {
    NoxDashboardView()
        .environment(AppEnvironment())
}
