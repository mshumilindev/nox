import SwiftUI
import AppKit
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
import UniformTypeIdentifiers

/// Native macOS Share Sheet — user explicitly picks destination (never auto-AirDrop).
enum NoxPresenceMeshShareBridge {
    static func presentShare(items: [Any], from view: NSView?) {
        let picker = NSSharingServicePicker(items: items)
        if let view {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        } else if let keyWindow = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: keyWindow, preferredEdge: .minY)
        } else {
            picker.show(relativeTo: .zero, of: NSApp.mainWindow?.contentView ?? NSView(), preferredEdge: .minY)
        }
    }

    static func importInviteFile(completion: @escaping (Data?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Import Nox pairing invite"
        panel.prompt = "Import"
        if panel.runModal() == .OK, let url = panel.url {
            completion(try? Data(contentsOf: url))
        } else {
            completion(nil)
        }
    }
}

struct NoxShareSheetButton: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "Share invite", target: context.coordinator, action: #selector(Coordinator.share))
        button.bezelStyle = .rounded
        context.coordinator.items = items
        context.coordinator.button = button
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.items = items
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var items: [Any] = []
        weak var button: NSButton?

        @objc func share() {
            guard let button else { return }
            NoxPresenceMeshShareBridge.presentShare(items: items, from: button)
        }
    }
}
