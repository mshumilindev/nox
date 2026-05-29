import Foundation
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
import Security

/// Stores Ed25519 private key material in Keychain with human-facing labels (not dev bundle IDs).
nonisolated enum NoxIdentityKeychain {
    private static let legacyService = "dev.nox.Nox.mesh.identity"
    private static let legacyAccountPrefix = "nox.mesh.signing."

    /// Shown in macOS Keychain prompts — must read like product copy, not an internal identifier.
    private static let service = "Nox Presence"
    private static let label = "Nox Presence"
    private static let description = "Signing key for trusted Nox environments on this Mac."

    static func account(for profile: NoxMeshProfile) -> String {
        profile.isDefault ? "Your environment" : "Environment (\(profile.displayName))"
    }

    static func savePrivateKey(_ data: Data, profile: NoxMeshProfile) throws {
        deletePrivateKey(profile: profile)
        var insert = baseQuery(profile: profile)
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(insert as CFDictionary, nil)
        guard status == errSecSuccess else {
            #if DEBUG
            try saveDevFallback(data, profile: profile)
            #else
            throw NoxMeshError.keychainFailed(status)
            #endif
            return
        }
    }

    static func loadPrivateKey(profile: NoxMeshProfile) throws -> Data? {
        if let data = copyMatching(query: baseQuery(profile: profile, returnData: true)) {
            return data
        }
        if let legacy = copyMatching(query: legacyQuery(profile: profile, returnData: true)) {
            try? savePrivateKey(legacy, profile: profile)
            return legacy
        }
        #if DEBUG
        return try loadDevFallback(profile: profile)
        #else
        return nil
        #endif
    }

    static func deletePrivateKey(profile: NoxMeshProfile) {
        SecItemDelete(baseQuery(profile: profile) as CFDictionary)
        SecItemDelete(legacyQuery(profile: profile) as CFDictionary)
        #if DEBUG
        let url = devFallbackURL(profile: profile)
        try? FileManager.default.removeItem(at: url)
        #endif
    }

    private static func baseQuery(profile: NoxMeshProfile, returnData: Bool = false) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(for: profile),
            kSecAttrLabel as String: label,
            kSecAttrDescription as String: description,
        ]
        if returnData {
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }
        return query
    }

    private static func legacyQuery(profile: NoxMeshProfile, returnData: Bool = false) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService,
            kSecAttrAccount as String: legacyAccountPrefix + profile.name,
        ]
        if returnData {
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }
        return query
    }

    private static func copyMatching(query: [String: Any]) -> Data? {
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    #if DEBUG
    private static func devFallbackURL(profile: NoxMeshProfile) -> URL {
        NoxPersistencePaths.meshIdentityDirectory
            .appendingPathComponent("DEV_ONLY_signing_\(profile.name).key")
    }

    private static func saveDevFallback(_ data: Data, profile: NoxMeshProfile) throws {
        NoxPersistencePaths.ensureDirectory(at: NoxPersistencePaths.meshIdentityDirectory)
        let url = devFallbackURL(profile: profile)
        try data.write(to: url, options: .completeFileProtection)
        NoxPresenceMeshDiagnostics.log("DEV: wrote signing key fallback to disk for profile \(profile.name)")
    }

    private static func loadDevFallback(profile: NoxMeshProfile) throws -> Data? {
        let url = devFallbackURL(profile: profile)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }
    #endif
}

nonisolated enum NoxMeshError: Error, LocalizedError, Equatable {
    case keychainFailed(OSStatus)
    case identityUnavailable
    case transportUnavailable
    case verificationFailed(String)
    case staleMessage
    case replayedNonce
    case inviteExpired
    case inviteAlreadyUsed

    var errorDescription: String? {
        switch self {
        case .keychainFailed(let s): "Keychain error \(s)"
        case .identityUnavailable: "Node identity unavailable"
        case .transportUnavailable: "Local transport unavailable"
        case .verificationFailed(let r): r
        case .staleMessage: "Message timestamp outside allowed window"
        case .replayedNonce: "Nonce already used"
        case .inviteExpired: "Pairing invite expired"
        case .inviteAlreadyUsed: "Pairing invite already used"
        }
    }
}
