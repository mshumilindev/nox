import SwiftUI

enum NoxAmbientHoverStyle: Sendable {
    case row
    case chip
    case card
    case inset
}

struct NoxAmbientHoverModifier: ViewModifier {
    let style: NoxAmbientHoverStyle
    var isSelected: Bool
    var cornerRadius: CGFloat?

    @State private var hovered = false

    func body(content: Content) -> some View {
        content
            .background(hoverBackground)
            .animation(.easeInOut(duration: NoxDesignTokens.Animation.surfaceFade), value: hovered)
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    hovered = true
                case .ended:
                    hovered = false
                }
            }
    }

    @ViewBuilder
    private var hoverBackground: some View {
        if hovered, !isSelected {
            switch style {
            case .row:
                RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.32))
            case .chip:
                Capsule(style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.38))
            case .card:
                RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                            .strokeBorder(NoxDesignTokens.ColorRole.border.opacity(0.2), lineWidth: 0.5)
                    )
            case .inset:
                RoundedRectangle(cornerRadius: resolvedRadius, style: .continuous)
                    .fill(NoxDesignTokens.ColorRole.surface.opacity(0.42))
            }
        }
    }

    private var resolvedRadius: CGFloat {
        cornerRadius ?? {
            switch style {
            case .row, .inset: NoxDesignTokens.Radius.sm
            case .chip: NoxDesignTokens.Radius.lg
            case .card: NoxDesignTokens.Radius.sm
            }
        }()
    }
}

extension View {
    func noxAmbientHover(
        _ style: NoxAmbientHoverStyle = .row,
        isSelected: Bool = false,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        modifier(NoxAmbientHoverModifier(
            style: style,
            isSelected: isSelected,
            cornerRadius: cornerRadius
        ))
    }
}
