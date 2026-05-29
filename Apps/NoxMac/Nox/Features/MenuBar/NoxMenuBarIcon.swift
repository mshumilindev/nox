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

enum NoxMenuBarIcon {
    /// Template image adapts to light/dark menu bar automatically.
    static func makeTemplateImage() -> NSImage {
        let base = NSImage(named: "NoxTrayTemplate")
            ?? NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in true }
        let image = base.copy() as? NSImage ?? base
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }
}

struct NoxMenuBarIconLabel: View {
    var body: some View {
        Image(nsImage: NoxMenuBarIcon.makeTemplateImage())
            .accessibilityLabel("Nox")
    }
}
