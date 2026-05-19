import Foundation

enum NoxContextObservationMatrix {
    static func build(
        snapshot: NoxActivitySnapshot,
        capabilities: NoxCapabilityState,
        domain: String?,
        documentURL: String?,
        browserFamily: Bool,
        mediaFamily: Bool
    ) -> [NoxContextObservationStatus] {
        NoxContextObservationChannel.allCases.map { channel in
            status(
                channel: channel,
                snapshot: snapshot,
                capabilities: capabilities,
                domain: domain,
                documentURL: documentURL,
                browserFamily: browserFamily,
                mediaFamily: mediaFamily
            )
        }
    }

    static func missingChannels(from statuses: [NoxContextObservationStatus]) -> [NoxContextObservationChannel] {
        statuses.filter { !$0.isAvailable }.map(\.channel)
    }

    private static func status(
        channel: NoxContextObservationChannel,
        snapshot: NoxActivitySnapshot,
        capabilities: NoxCapabilityState,
        domain: String?,
        documentURL: String?,
        browserFamily: Bool,
        mediaFamily: Bool
    ) -> NoxContextObservationStatus {
        switch channel {
        case .foregroundApp:
            return make(channel, true, nil)
        case .windowTitle:
            if capabilities.windowAwarenessAvailable, let title = snapshot.windowTitle, !title.isEmpty {
                return make(channel, true, nil)
            }
            return make(channel, false, capabilities.accessibilityGranted
                ? "No focused window title from AX"
                : "Accessibility required for window title")
        case .browserURL:
            if let documentURL, !documentURL.isEmpty, browserFamily {
                return make(channel, true, nil)
            }
            return make(channel, false, browserFamily
                ? "Browser URL not exposed (grant Accessibility)"
                : "Not a browser foreground app")
        case .browserDomain:
            if let domain, !domain.isEmpty {
                return make(channel, true, nil)
            }
            return make(channel, false, "Domain not resolved from URL or title")
        case .browserPageTitle:
            if browserFamily, let title = snapshot.windowTitle, !title.isEmpty {
                return make(channel, true, nil)
            }
            return make(channel, false, "Browser page title unavailable")
        case .interactionSignals:
            if capabilities.interactionSignalsAvailable {
                return make(channel, true, nil)
            }
            return make(channel, false, "Interaction collector inactive")
        case .mediaMetadata:
            if mediaFamily {
                return make(channel, true, "Inferred from media player family")
            }
            return make(channel, false, "System Now Playing integration not enabled")
        case .screenContext:
            if capabilities.screenRecordingGranted {
                return make(channel, true, nil)
            }
            return make(channel, false, "Screen Recording not granted")
        case .accessibility:
            if capabilities.accessibilityGranted {
                return make(channel, true, nil)
            }
            return make(channel, false, "Accessibility not granted")
        case .automation:
            return make(channel, false, "Automation permission not integrated in this build")
        }
    }

    private static func make(
        _ channel: NoxContextObservationChannel,
        _ available: Bool,
        _ blocker: String?
    ) -> NoxContextObservationStatus {
        NoxContextObservationStatus(channel: channel, isAvailable: available, blocker: blocker)
    }
}
