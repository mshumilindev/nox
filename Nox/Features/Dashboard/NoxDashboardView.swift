import SwiftUI

/// Legacy entry — ambient shell is the primary surface.
struct NoxDashboardView: View {
    var body: some View {
        NoxAmbientShellView()
    }
}

#Preview {
    NoxDashboardView()
        .environment(AppEnvironment())
}
