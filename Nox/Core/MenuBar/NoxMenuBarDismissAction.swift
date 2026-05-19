import SwiftUI

private struct NoxMenuBarDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var noxMenuBarDismiss: (() -> Void)? {
        get { self[NoxMenuBarDismissKey.self] }
        set { self[NoxMenuBarDismissKey.self] = newValue }
    }
}
