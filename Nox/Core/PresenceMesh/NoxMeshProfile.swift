import Foundation

/// Dev / multi-instance profile — isolates mesh identity, trust store, and listener port.
nonisolated struct NoxMeshProfile: Equatable, Sendable, Codable {
    let name: String

    static let `default` = NoxMeshProfile(name: "default")

    var isDefault: Bool { name == "default" }

    /// Legacy folder name — memory always uses shared `Nox`; mesh uses `PresenceMesh/Profiles/<name>`.
    var storageFolderName: String {
        if isDefault { return "Nox" }
        return "Nox-dev-\(name)"
    }

    /// Subpath under shared `Nox/PresenceMesh/` for profile-scoped mesh state.
    var meshProfileSubpath: String {
        if isDefault { return "PresenceMesh" }
        return "PresenceMesh/Profiles/\(name)"
    }

    /// Local HTTP pairing port — avoids collisions between co-located dev nodes.
    var meshPort: UInt16 {
        switch name {
        case "default": return 9120
        case "node-a": return 9121
        case "node-b": return 9122
        default:
            let hash = abs(name.hashValue)
            return UInt16(9130 + (hash % 80))
        }
    }

    var displayName: String {
        isDefault ? "Primary" : name
    }

    static func resolve() -> NoxMeshProfile {
        let env = ProcessInfo.processInfo.environment
        if let profile = env["NOX_PROFILE"], !profile.isEmpty {
            return NoxMeshProfile(name: profile)
        }
        for arg in ProcessInfo.processInfo.arguments {
            if arg.hasPrefix("-nox-profile=") {
                let value = String(arg.dropFirst("-nox-profile=".count))
                if !value.isEmpty { return NoxMeshProfile(name: value) }
            }
            if arg == "-nox-profile", let idx = ProcessInfo.processInfo.arguments.firstIndex(of: arg),
               idx + 1 < ProcessInfo.processInfo.arguments.count {
                let value = ProcessInfo.processInfo.arguments[idx + 1]
                if !value.isEmpty { return NoxMeshProfile(name: value) }
            }
        }
        return .default
    }
}

nonisolated enum NoxMeshRuntime {
    static let profile: NoxMeshProfile = NoxMeshProfile.resolve()

    #if DEBUG
    static var isDevMode: Bool { true }
    #else
    static var isDevMode: Bool { !profile.isDefault }
    #endif
}
