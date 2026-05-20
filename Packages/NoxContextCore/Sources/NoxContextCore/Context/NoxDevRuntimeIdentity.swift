import Foundation
import NoxCore

public enum NoxDevRuntimeIdentity {
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }

    public static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Nox"
    }

    public static var isRunningFromXcode: Bool {
        let env = ProcessInfo.processInfo.environment
        if env["XPC_SERVICE_NAME"]?.contains("com.apple.dt.Xcode") == true { return true }
        if env["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil { return true }
        if let parent = env["XPC_PARENT_PID"], !parent.isEmpty { return true }
        return false
    }

    public static var launchContextSummary: String {
        if isRunningFromXcode {
            return "Xcode-managed process (grant Accessibility to Nox in Xcode run or use standalone build)"
        }
        return "Standalone app bundle"
    }

    public static var permissionTargetSummary: String {
        "\(appName) (\(bundleIdentifier))"
    }

    public static var standaloneBuildHint: String {
        "Build with xcodebuild, open DerivedData/.../Debug/Nox.app, grant Accessibility to that binary."
    }
}
