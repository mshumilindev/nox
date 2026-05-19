import SwiftUI

struct NoxLocalFirstBadge: View {
    var body: some View {
        HStack(spacing: NoxSpacing.xs) {
            NoxIcon(systemName: "lock.shield", role: .inline)
            Text(NoxTrustContent.localBadge)
                .font(NoxTypography.metadata)
        }
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.82))
    }
}
