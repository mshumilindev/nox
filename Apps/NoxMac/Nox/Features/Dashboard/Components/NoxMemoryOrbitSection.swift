import SwiftUI
import NoxMemoryCore
import NoxDesignCore

struct NoxMemoryOrbitSection: View {
    let ownership: NoxMemoryEcologyOwnership
    let items: [NoxMemoryOrbitItem]

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            NoxMemoryEcologySectionHeader(
                title: NoxMemoryEcologyOwnershipResolver.orbitName,
                subtitle: ownership.orbitSectionSubtitle,
                weight: .orbit,
                isPrimaryLayer: ownership.primaryLayer == .orbit
            )

            Group {
                if items.isEmpty {
                    Text(NoxMemoryEcologyCopy.orbitEmpty)
                        .font(NoxTypography.body)
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: NoxSpacing.sm) {
                        ForEach(items) { item in
                            orbitCard(item)
                        }
                    }
                }
            }
            .opacity(
                ownership.primaryLayer == .orbit
                    ? NoxMemoryEcologyLayerVisualWeight.galaxy.contentOpacity
                    : NoxMemoryEcologyLayerVisualWeight.orbit.contentOpacity
            )
            .noxSurface(ownership.primaryLayer == .orbit ? .standard : .soft, padding: NoxSpacing.lg)

            if let note = ownership.externalLayerNote, ownership.primaryLayer == .orbit {
                Text(note)
                    .font(NoxTypography.caption)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func orbitCard(_ item: NoxMemoryOrbitItem) -> some View {
        VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
            Text(item.deviceName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.88))
            Text(item.roleLine)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(NoxDesignTokens.ColorRole.presenceActive.opacity(0.85))
            Text(item.detail)
                .font(.system(size: 11))
                .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, NoxSpacing.xs)
    }
}
