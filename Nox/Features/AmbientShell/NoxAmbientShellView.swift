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

    private var contentAtmosphereOpacity: Double {
        0.40
    }

    private var atmosphericState: NoxAtmosphericState {
        .night
    }

    var body: some View {
        let windowSize = environment.preferences.windowMode.size
        shellBody
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .frame(width: windowSize.width, height: windowSize.height)
            .background(
                NoxAtmosphereBackground(density: environment.memoryDensity, state: atmosphericState)
            )
            .onChange(of: environment.preferences.windowMode) { _, _ in
                environment.syncDashboardWindowFrame(animated: false)
            }
            .task {
                environment.startIfNeeded()
                showOnboarding = !environment.preferences.hasSeenTrustOnboarding
            }
            .sheet(isPresented: $showOnboarding) {
                NoxPermissionOnboardingView()
            }
            .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var shellBody: some View {
        VStack(spacing: 0) {
            if isCompact {
                NoxShellChrome(destination: activeDestination, compact: true)
                NoxCompactNavigationBar()
                contentWell
            } else {
                HStack(alignment: .top, spacing: 0) {
                    if showsRail {
                        NoxSemanticNavigationRail()
                    }

                    VStack(spacing: 0) {
                        NoxShellChrome(destination: activeDestination, compact: false)
                        contentWell
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        .background(NoxDesignTokens.ColorRole.canvas.opacity(contentAtmosphereOpacity))
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
        case .observatory:
            NoxObservatoryView()
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
        case .observatory:
            NoxObservatoryView()
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
