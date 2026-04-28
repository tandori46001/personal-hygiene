import Foundation

/// Round-25 slice T4.24 (deferred from round 24): persists the URL of the
/// last backup the user exported (via the share-sheet) so Settings can
/// surface a "Restore most recent backup" shortcut. Stored as a security-
/// scoped bookmark — file URLs from `ShareSheet` may originate from a
/// container the app cannot re-read after relaunch without one.
public enum MostRecentBackupStore {

    public static let bookmarkKey = "backup.mostRecent.bookmark"
    public static let nameKey = "backup.mostRecent.name"
    public static let exportedAtKey = "backup.mostRecent.exportedAt"

    public static func record(url: URL, in defaults: UserDefaults = .standard) {
        guard let bookmark = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil) else {
            return
        }
        defaults.set(bookmark, forKey: bookmarkKey)
        defaults.set(url.lastPathComponent, forKey: nameKey)
        defaults.set(Date().timeIntervalSince1970, forKey: exportedAtKey)
    }

    public static func recordedURL(in defaults: UserDefaults = .standard) -> URL? {
        guard let bookmark = defaults.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else { return nil }
        return url
    }

    public static func recordedName(in defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: nameKey)
    }

    public static func recordedAt(in defaults: UserDefaults = .standard) -> Date? {
        let stored = defaults.double(forKey: exportedAtKey)
        guard stored > 0 else { return nil }
        return Date(timeIntervalSince1970: stored)
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: bookmarkKey)
        defaults.removeObject(forKey: nameKey)
        defaults.removeObject(forKey: exportedAtKey)
    }
}
