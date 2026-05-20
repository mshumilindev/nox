import Foundation

/// Stable on-disk location for all Nox local data (survives Xcode restarts).
nonisolated enum NoxPersistencePaths {
    private static let databaseFileName = "timeline.db"
    private static let sharedFolderName = "Nox"

    /// Shared Application Support folder — memory, timeline, and reflections always live here.
    static var appFolderName: String { sharedFolderName }

    static var applicationSupportDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let folder = support?.appendingPathComponent(sharedFolderName, isDirectory: true)
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(sharedFolderName, isDirectory: true)
        ensureDirectory(at: folder)
        return folder
    }

    static var databaseURL: URL {
        applicationSupportDirectory.appendingPathComponent(databaseFileName)
    }

    /// Presence Mesh data is profile-scoped; memory and timeline are not.
    private static var meshProfileRoot: URL {
        let profile = NoxMeshRuntime.profile
        if profile.isDefault {
            return applicationSupportDirectory.appendingPathComponent("PresenceMesh", isDirectory: true)
        }
        return applicationSupportDirectory
            .appendingPathComponent("PresenceMesh/Profiles/\(profile.name)", isDirectory: true)
    }

    static var meshIdentityDirectory: URL {
        meshProfileRoot.appendingPathComponent("identity", isDirectory: true)
    }

    static var meshDataDirectory: URL {
        meshProfileRoot
    }

    static func ensureDirectory(at url: URL? = nil) {
        let target = url ?? applicationSupportDirectory
        if !FileManager.default.fileExists(atPath: target.path) {
            try? FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        }
    }
}
