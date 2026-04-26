import Foundation

/// Single source of truth for build identifiers shown in the Settings footer
/// + Diagnostics screen. Reads `CFBundleShortVersionString` + `CFBundleVersion`
/// from the main bundle's Info.plist; commit SHA falls back to "dev" when not
/// injected (we don't currently bake one in via xcconfig — the local working
/// tree might not match a known commit).
public enum BuildInfo {

    public static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    public static var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// Read from `PERSONAL_HYGIENE_COMMIT_SHA` Info.plist key, falling back to
    /// "dev" when absent. To inject a real SHA at build time, add the key to
    /// the iOS app target's Info.plist + an xcconfig assignment from
    /// `$(PERSONAL_HYGIENE_COMMIT_SHA)` set by CI.
    public static var commitSHA: String {
        Bundle.main.infoDictionary?["PERSONAL_HYGIENE_COMMIT_SHA"] as? String ?? "dev"
    }

    /// Compact "vX.Y.Z (build N) — sha" suitable for a footer label.
    public static var shortDescriptor: String {
        "v\(marketingVersion) (\(bundleVersion)) — \(commitSHA)"
    }
}
