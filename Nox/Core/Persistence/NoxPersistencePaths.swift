import Foundation

/// Stable on-disk location for all Nox local data (survives Xcode restarts).
nonisolated enum NoxPersistencePaths {
    private static let appFolderName = "Nox"
    private static let databaseFileName = "timeline.db"

    static var applicationSupportDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let folder = support?.appendingPathComponent(appFolderName, isDirectory: true)
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(appFolderName, isDirectory: true)
        ensureDirectory(at: folder)
        return folder
    }

    static var databaseURL: URL {
        applicationSupportDirectory.appendingPathComponent(databaseFileName)
    }

    static func ensureDirectory(at url: URL? = nil) {
        let target = url ?? applicationSupportDirectory
        if !FileManager.default.fileExists(atPath: target.path) {
            try? FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        }
    }
}
