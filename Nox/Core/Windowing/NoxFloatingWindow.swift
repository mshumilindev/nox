import AppKit

/// Floating panel — standard titlebar drag band, content not under titlebar hit zone.
final class NoxFloatingWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
