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

struct NoxSettingsView: View {
    @StateObject private var launchAtLogin = NoxLaunchAtLoginController()

    var body: some View {
        Form {
            Section("Startup") {
                Toggle(
                    "Launch Nox at login",
                    isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    )
                )

                Text(launchAtLogin.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let errorMessage = launchAtLogin.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                if launchAtLogin.requiresApproval {
                    Button("Open Login Items Settings") {
                        launchAtLogin.openLoginItemSettings()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 440, height: 180)
        .onAppear {
            launchAtLogin.refresh()
        }
    }
}
