import AppKit
import SwiftUI

/// Continuous triskelion rotation via Core Animation (reliable in modal overlays).
struct NoxRotatingTriskelionView: NSViewRepresentable {
    let size: CGFloat
    let isSpinning: Bool

    func makeNSView(context: Context) -> NoxRotatingTriskelionNSView {
        let view = NoxRotatingTriskelionNSView()
        view.applySize(size)
        return view
    }

    func updateNSView(_ nsView: NoxRotatingTriskelionNSView, context: Context) {
        nsView.applySize(size)
        if isSpinning {
            nsView.startSpinning()
        } else {
            nsView.stopSpinning()
        }
    }
}

final class NoxRotatingTriskelionNSView: NSView {
    private let imageView = NSImageView()

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageView.image = NSImage(named: "NoxTriskelionMark")
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        if #available(macOS 12.0, *) {
            imageView.contentTintColor = NSColor.white
        }
        addSubview(imageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        imageView.frame = bounds
        guard let layer = imageView.layer else { return }
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    func applySize(_ side: CGFloat) {
        setFrameSize(NSSize(width: side, height: side))
        needsLayout = true
    }

    func startSpinning() {
        layoutSubtreeIfNeeded()
        guard let layer = imageView.layer else { return }

        layer.removeAnimation(forKey: "noxSpin")
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = Double.pi * 2
        spin.duration = 0.85
        spin.repeatCount = .infinity
        spin.isRemovedOnCompletion = false
        layer.add(spin, forKey: "noxSpin")

        layer.removeAnimation(forKey: "noxPulse")
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.86
        pulse.toValue = 1.0
        pulse.duration = 0.85
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.isRemovedOnCompletion = false
        layer.add(pulse, forKey: "noxPulse")
    }

    func stopSpinning() {
        imageView.layer?.removeAnimation(forKey: "noxSpin")
        imageView.layer?.removeAnimation(forKey: "noxPulse")
    }
}
