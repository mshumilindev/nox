import SwiftUI

struct NoxMemoryStatsView: View {
    let stats: NoxMemoryDayStats
    var dayOverview: String?

    var body: some View {
        if let dayOverview, !dayOverview.isEmpty {
            Text(dayOverview)
                .font(NoxTypography.body)
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
