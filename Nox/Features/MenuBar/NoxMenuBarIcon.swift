import AppKit
import SwiftUI

enum NoxMenuBarIcon {
    /// Template image adapts to light/dark menu bar automatically.
    static func makeTemplateImage() -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let base = NSImage(
            systemSymbolName: NoxDesignTokens.Icon.menuBarSymbol,
            accessibilityDescription: "Nox"
        ) ?? NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in true }

        let image = (base.withSymbolConfiguration(configuration) ?? base).copy() as? NSImage ?? base
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
