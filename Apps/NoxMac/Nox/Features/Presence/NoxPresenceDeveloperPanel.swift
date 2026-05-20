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

/// Collapsed developer tools — never dominates the Presence experience.
struct NoxPresenceDeveloperPanel: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var showAdvanced = false

    private var mesh: PresenceMeshManager { environment.presenceMesh }

    var body: some View {
        NoxCollapsibleSection(title: "Developer Mode", defaultExpanded: false) {
            VStack(alignment: .leading, spacing: NoxSpacing.md) {
                Text("Simulate and validate multi-device presence on this Mac.")
                    .noxMetadata()

                Button("Launch Secondary Node") {
                    Task { await mesh.launchSimulatedSecondaryNode() }
                }
                .buttonStyle(NoxPresencePrimaryButtonStyle())

                Button("Run Simulated Nearby Presence") {
                    Task { await mesh.launchSimulatedSecondaryNode() }
                }

                Button("Import Continuation File…") {
                    NoxPresenceMeshShareBridge.importInviteFile { data in
                        guard let data else { return }
                        Task { try? await mesh.importInviteData(data) }
                    }
                }

                Button("Reset Environment", role: .destructive) {
                    mesh.resetIdentity()
                }

                if showAdvanced {
                    advancedFields
                }

                Button(showAdvanced ? "Hide Advanced" : "Show Advanced") {
                    showAdvanced.toggle()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)
            }
            .padding(.top, NoxSpacing.xs)
        }
    }

    @ViewBuilder
    private var advancedFields: some View {
        #if DEBUG
        if !mesh.diagnostics.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(mesh.diagnostics.suffix(24), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.7))
                    }
                }
            }
            .frame(maxHeight: 100)
        }
        #endif
    }
}
