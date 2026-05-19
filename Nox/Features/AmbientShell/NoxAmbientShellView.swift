import SwiftUI

struct NoxAmbientShellView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var showOnboarding = false

    private var activeDestination: NoxSemanticDestination {
        environment.preferences.navigationDestination
    }

    private var isCompact: Bool {
        environment.preferences.windowMode == .compact
    }

    var body: some View {
        VStack(spacing: 0) {
            NoxShellChrome(destination: activeDestination, compact: isCompact)

            if isCompact {
                NoxCompactNavigationBar()
            }

            HStack(alignment: .top, spacing: 0) {
                if showsRail {
                    NoxSemanticNavigationRail()
                }

                contentWell
                    .layoutPriority(1)
            }
        }
        .frame(
            width: environment.preferences.windowMode.size.width,
            height: environment.preferences.windowMode.size.height
        )
        .background(
            NoxAtmosphereBackground(density: environment.memoryDensity)
        )
        .preferredColorScheme(.dark)
        .task {
            environment.startIfNeeded()
            showOnboarding = !environment.preferences.hasSeenTrustOnboarding
        }
        .sheet(isPresented: $showOnboarding) {
            NoxPermissionOnboardingView()
        }
    }

    private var showsRail: Bool {
        !isCompact
    }

    private var contentWell: some View {
        ScrollView(.vertical, showsIndicators: false) {
            shellContent
                .padding(NoxMaterials.contentPadding)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
        .background(NoxDesignTokens.ColorRole.canvas.opacity(0.35))
        .animation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade), value: activeDestination)
    }

    @ViewBuilder
    private var shellContent: some View {
        Group {
            if environment.preferences.windowMode == .deepReflection {
                deepDestinationView(for: activeDestination)
            } else {
                destinationView(for: activeDestination)
            }
        }
        .id(activeDestination)
    }

    @ViewBuilder
    private func deepDestinationView(for destination: NoxSemanticDestination) -> some View {
        switch destination {
        case .patterns:
            NoxDeepPatternsSurfaceView()
        case .reflections:
            NoxDeepReflectionSurfaceView()
        default:
            destinationView(for: destination)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: NoxSemanticDestination) -> some View {
        switch destination {
        case .now:
            NoxNowSurfaceView()
        case .threads:
            NoxThreadsSurfaceView()
        case .memory:
            NoxMemorySurfaceView()
        case .patterns:
            NoxPatternsSurfaceView()
        case .reflections:
            NoxReflectionsSurfaceView()
        case .local:
            NoxLocalSurfaceView()
        case .trust:
            NoxTrustCenterView()
        }
    }
}

#Preview {
    NoxAmbientShellView()
        .environment(AppEnvironment())
}
