import AppKit
import Foundation
import NoxShrineCore

private struct ShrineSavedOrigin: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
}

/// Per-display mini bubble origin. UserDefaults only — not canonical memory.
@MainActor
final class ShrinePositionStore {
    private let defaults: UserDefaults
    private let storageKey = "dev.nox.shrine.miniPositions"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func origin(for screen: NSScreen) -> CGPoint? {
        let key = NoxShrineMiniBubblePlacement.displayKey(screenFrame: ShrineScreenGeometry.screenRect(screen.frame))
        guard let saved = loadAll()[key] else { return nil }
        return CGPoint(x: saved.x, y: saved.y)
    }

    func save(origin: CGPoint, for screen: NSScreen) {
        let key = NoxShrineMiniBubblePlacement.displayKey(screenFrame: ShrineScreenGeometry.screenRect(screen.frame))
        var all = loadAll()
        all[key] = ShrineSavedOrigin(x: origin.x, y: origin.y)
        persist(all)
    }

    func resolvedOrigin(for screen: NSScreen, panelSize: CGSize) -> CGPoint {
        let visible = ShrineScreenGeometry.screenRect(screen.visibleFrame)
        let saved = origin(for: screen).map { ShrineScreenGeometry.point($0) }
        let resolved = NoxShrineMiniBubblePlacement.resolvedOrigin(
            savedOrigin: saved,
            visibleFrame: visible,
            panelSize: ShrineScreenGeometry.panelSize(panelSize)
        )
        return ShrineScreenGeometry.cgPoint(resolved)
    }

    func reset(on screen: NSScreen, panelSize: CGSize) -> CGPoint {
        let originPoint = NoxShrineMiniBubblePlacement.bottomRightOrigin(
            visibleFrame: ShrineScreenGeometry.screenRect(screen.visibleFrame),
            panelSize: ShrineScreenGeometry.panelSize(panelSize)
        )
        let origin = ShrineScreenGeometry.cgPoint(originPoint)
        save(origin: origin, for: screen)
        return origin
    }

    func screen(containing panelFrame: NSRect) -> NSScreen {
        let center = NSPoint(x: panelFrame.midX, y: panelFrame.midY)
        if let match = NSScreen.screens.first(where: { $0.frame.contains(center) }) {
            return match
        }
        if let match = NSScreen.screens.first(where: { $0.frame.intersects(panelFrame) }) {
            return match
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    func mainScreen() -> NSScreen {
        NSScreen.main ?? NSScreen.screens[0]
    }

    private func loadAll() -> [String: ShrineSavedOrigin] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: ShrineSavedOrigin].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func persist(_ all: [String: ShrineSavedOrigin]) {
        guard let data = try? JSONEncoder().encode(all) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
