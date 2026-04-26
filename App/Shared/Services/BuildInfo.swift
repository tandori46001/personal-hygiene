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

    /// Read from a `CommitSHA.txt` resource baked into the app bundle.
    /// `scripts/deploy-iphone.sh` writes the current `git rev-parse --short
    /// HEAD` into the file before each build; the checked-in default is
    /// `"dev"` so plain `xcodebuild` runs without the script still produce a
    /// readable value.
    public static var commitSHA: String {
        guard let url = Bundle.main.url(forResource: "CommitSHA", withExtension: "txt"),
              let data = try? String(contentsOf: url, encoding: .utf8) else {
            return "dev"
        }
        let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "dev" : trimmed
    }

    /// Compact "vX.Y.Z (build N) — sha" suitable for a footer label.
    public static var shortDescriptor: String {
        "v\(marketingVersion) (\(bundleVersion)) — \(commitSHA)"
    }
}
