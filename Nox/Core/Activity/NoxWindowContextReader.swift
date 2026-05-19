import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum NoxWindowContextReader {
    static func focusedWindowTitle(for bundleId: String, accessibilityGranted: Bool) -> String? {
        guard accessibilityGranted else { return nil }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        guard appResult == .success, let appRef = focusedApp else { return nil }
        let appElement = appRef as! AXUIElement

        var focusedWindow: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )
        guard windowResult == .success, let windowRef = focusedWindow else { return nil }
        let windowElement = windowRef as! AXUIElement

        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(
            windowElement,
            kAXTitleAttribute as CFString,
            &titleValue
        )
        guard titleResult == .success, let title = titleValue as? String, !title.isEmpty else {
            return nil
        }

        return title
    }

    static func focusedDocumentURL(accessibilityGranted: Bool) -> String? {
        guard accessibilityGranted else { return nil }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        ) == .success,
            let appRef = focusedApp else { return nil }
        let appElement = appRef as! AXUIElement

        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        ) == .success,
            let windowRef = focusedWindow else { return nil }
        let windowElement = windowRef as! AXUIElement

        var documentValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            windowElement,
            kAXDocumentAttribute as CFString,
            &documentValue
        ) == .success,
            let documentValue else { return nil }

        if let urlString = documentValue as? String, !urlString.isEmpty {
            return urlString
        }
        if let url = documentValue as? URL {
            return url.absoluteString
        }
        return nil
    }

    static func fallbackWindowTitle(for bundleId: String) -> String? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                  let runningApp = NSRunningApplication(processIdentifier: ownerPID),
                  runningApp.bundleIdentifier == bundleId,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let title = window[kCGWindowName as String] as? String,
                  !title.isEmpty else {
                continue
            }
            return title
        }

        return nil
    }
}
