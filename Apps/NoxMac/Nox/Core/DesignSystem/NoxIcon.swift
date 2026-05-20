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

/// Unified SF Symbol rendering — consistent optical weight across the shell.
struct NoxIcon: View {
    enum Role {
        case rail
        case chrome
        case inline
        case section
    }

    let systemName: String
    var role: Role = .inline
    var emphasized: Bool = false
    var tint: Color?

    var body: some View {
        Image(systemName: NoxSFSymbol.validated(systemName, fallback: "circle.fill"))
            .font(.system(size: pointSize, weight: weight))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(foreground)
            .frame(width: frameSize, height: frameSize, alignment: .center)
    }

    private var pointSize: CGFloat {
        switch role {
        case .rail: NoxDesignTokens.SymbolSize.rail
        case .chrome: NoxDesignTokens.SymbolSize.chrome
        case .inline: NoxDesignTokens.SymbolSize.inline
        case .section: NoxDesignTokens.SymbolSize.section
        }
    }

    private var frameSize: CGFloat {
        switch role {
        case .rail: 20
        case .chrome: 18
        case .inline: 16
        case .section: 14
        }
    }

    private var weight: Font.Weight {
        switch role {
        case .rail, .chrome: .regular
        case .inline, .section: .regular
        }
    }

    private var foreground: Color {
        if let tint {
            return tint
        }
        if emphasized {
            return NoxDesignTokens.ColorRole.accent.opacity(0.88)
        }
        switch role {
        case .rail, .inline:
            return NoxDesignTokens.ColorRole.textSecondary.opacity(0.82)
        case .chrome:
            return NoxDesignTokens.ColorRole.accent.opacity(0.78)
        case .section:
            return NoxDesignTokens.ColorRole.accent.opacity(0.62)
        }
    }
}
