import SwiftUI
import NoxCore
import NoxDesignCore

/// Rail / compact navigation label — feature destinations vs memory ecology mode.
struct NoxSemanticNavigationLabel: View {
    let title: String
    var secondaryHint: String?
    var isEcologyMode: Bool
    var selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(selected ? Font.system(size: 11, weight: .medium) : NoxTypography.railLabel)
                .foregroundStyle(primaryForeground)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            if let secondaryHint, !secondaryHint.isEmpty {
                Text(secondaryHint)
                    .font(.system(size: 10))
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.52))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var primaryForeground: Color {
        if selected {
            return NoxDesignTokens.ColorRole.textPrimary.opacity(isEcologyMode ? 0.88 : 0.92)
        }
        return NoxDesignTokens.ColorRole.textSecondary.opacity(isEcologyMode ? 0.58 : 0.68)
    }
}
