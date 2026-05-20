import SwiftUI

/// Settings row — full-width tap toggles the switch; subtle hover, no button chrome.
struct NoxSettingsToggleRow: View {
    let title: String
    var detail: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: NoxSpacing.md) {
            VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                Text(title)
                    .font(NoxTypography.continuityDetail)
                    .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary.opacity(0.9))
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .noxMetadata()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .padding(.top, 1)
        }
        .padding(.vertical, NoxSpacing.sm)
        .padding(.horizontal, NoxSpacing.xs)
        .contentShape(Rectangle())
        .noxAmbientHover(.row)
        .onTapGesture { isOn.toggle() }
    }
}
