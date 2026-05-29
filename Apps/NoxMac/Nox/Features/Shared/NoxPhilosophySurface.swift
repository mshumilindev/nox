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
import NoxShrineCore

/// Understated philosophy surface — discovered, not advertised.
struct NoxPhilosophySurface: View {
    var presence: NoxPresenceState = .quiet
    var style: Style = .footer
    var showsLocalNote: Bool = true

    enum Style {
        case footer
        case compact
        case emergence
    }

    private var emphasis: NoxPhilosophy.Emphasis {
        NoxPhilosophy.emphasis(for: presence)
    }

    var body: some View {
        switch style {
        case .footer:
            footerBody
        case .compact:
            compactBody
        case .emergence:
            phasedBody(spacing: NoxSpacing.xs)
        }
    }

    private var footerBody: some View {
        VStack(alignment: .leading, spacing: NoxSpacing.sm) {
            phasedBody(spacing: NoxSpacing.xxs)

            if showsLocalNote {
                Text(NoxPhilosophy.localNote)
                    .font(NoxTypography.philosophy)
                    .foregroundStyle(secondaryText.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, NoxSpacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(NoxPhilosophy.inline) \(NoxPhilosophy.localNote)")
    }

    private var compactBody: some View {
        Text(NoxPhilosophy.inline)
            .font(NoxTypography.philosophy)
            .foregroundStyle(secondaryText.opacity(0.82))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, NoxSpacing.xs)
            .accessibilityLabel(NoxPhilosophy.inline)
    }

    private func phasedBody(spacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(NoxPhilosophy.phases, id: \.self) { phase in
                Text(phase.rawValue)
                    .font(NoxTypography.philosophy)
                    .foregroundStyle(secondaryText.opacity(NoxPhilosophy.lineOpacity(for: phase, emphasis: emphasis)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NoxPhilosophy.inline)
    }

    private var secondaryText: Color {
        NoxDesignTokens.ColorRole.textSecondary
    }
}

#Preview("Footer") {
    NoxPhilosophySurface(presence: .quiet, style: .footer)
        .padding()
        .frame(width: NoxDesignTokens.Window.width)
}

#Preview("Compact") {
    NoxPhilosophySurface(presence: .flow, style: .compact)
        .padding()
        .frame(width: NoxSpacing.menuBarWidth)
}
