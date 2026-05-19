import AppKit
import SwiftUI

/// Narrow drag strip — must not sit behind interactive SwiftUI controls.
struct NoxWindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NoxWindowDragView {
        let view = NoxWindowDragView()
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NoxWindowDragView, context: Context) {}
}

final class NoxWindowDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    /// Background AppKit views must not steal clicks from SwiftUI controls above them.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }
        return super.hitTest(point) === self ? self : nil
    }
}

extension View {
    /// Full-row tap target — apply inside `Button` labels, not outside the button.
    func noxHitTarget(minHeight: CGFloat = 40) -> some View {
        frame(maxWidth: .infinity, minHeight: minHeight, alignment: .center)
            .contentShape(Rectangle())
    }
}
