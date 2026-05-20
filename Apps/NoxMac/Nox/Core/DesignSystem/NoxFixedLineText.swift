import SwiftUI
import NoxCore
import NoxPlatformContracts
import NoxContextCore
import NoxSemanticCore
import NoxMemoryCore
import NoxContinuityCore
import NoxBehavioralIntelligenceCore
import NoxAmbientUtilityCore
import NoxSystemStateCore
import NoxObservatoryCore
import NoxPresenceCore
import NoxDesignCore

/// Reserves vertical space so sibling cards/rows stay the same height when copy is optional.
struct NoxFixedLineText: View {
    let text: String?
    var lineHeight: CGFloat = NoxSurfaceLayout.timelineMetadataLineHeight
    var font: Font = NoxTypography.caption
    var color: Color = NoxDesignTokens.ColorRole.textSecondary.opacity(0.58)

    var body: some View {
        Text(text ?? " ")
            .font(font)
            .foregroundStyle(text == nil ? .clear : color)
            .lineLimit(1)
            .frame(height: lineHeight, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
