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

struct NoxMemorySearchField: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    HStack(spacing: NoxSpacing.sm) {
      NoxIcon(systemName: "magnifyingglass", role: .inline)
        .font(.system(size: NoxDesignTokens.SymbolSize.sm))
        .foregroundStyle(NoxDesignTokens.ColorRole.textSecondary)

      TextField("Filter memory…", text: Binding(
        get: { environment.memorySearchText },
        set: { environment.setMemorySearch($0) }
      ))
      .textFieldStyle(.plain)
      .font(NoxTypography.body)
      .foregroundStyle(NoxDesignTokens.ColorRole.textPrimary)
    }
    .padding(.horizontal, NoxSpacing.md)
    .padding(.vertical, NoxSpacing.sm)
    .background(
      RoundedRectangle(cornerRadius: NoxDesignTokens.Radius.sm, style: .continuous)
        .fill(NoxDesignTokens.ColorRole.surfaceElevated.opacity(NoxDesignTokens.Opacity.subtle))
    )
  }
}
