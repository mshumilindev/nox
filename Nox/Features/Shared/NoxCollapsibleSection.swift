import SwiftUI

struct NoxCollapsibleSection<Content: View>: View {
    let title: String
    var subtitle: String?
    var defaultExpanded: Bool
    @ViewBuilder let content: () -> Content

    @State private var isExpanded: Bool

    init(
        title: String,
        subtitle: String? = nil,
        defaultExpanded: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.defaultExpanded = defaultExpanded
        self.content = content
        _isExpanded = State(initialValue: defaultExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.md) {
            Button {
                withAnimation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: NoxSpacing.sm) {
                    VStack(alignment: .leading, spacing: NoxSpacing.xxs) {
                        Text(title)
                            .noxSectionLabel()
                        if let subtitle, !isExpanded {
                            Text(subtitle)
                                .noxMetadata()
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: NoxSpacing.sm)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: NoxDesignTokens.SymbolSize.section, weight: .light))
                        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary.opacity(0.65))
                }
                .noxHitTarget(minHeight: 36)
            }
            .buttonStyle(.noxBorderless(hover: .row))

            if isExpanded {
                VStack(alignment: .leading, spacing: NoxSpacing.cardStack) {
                    content()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
