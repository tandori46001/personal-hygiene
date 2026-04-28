import Foundation

/// Round-13 slice 26: lets the user pick a backup auto-frequency. The
/// scheduler that actually runs the backup is a future phase (PRD M11);
/// this store captures the *intent* so the future scheduler can read it.
public enum BackupAutoFrequencyStore {

    public enum Frequency: String, Sendable, CaseIterable {
        case off
        case weekly
        case daily
    }

    public static let key = "backup.autoFrequency"

    public static func current(defaults: UserDefaults = .standard) -> Frequency {
        guard let raw = defaults.string(forKey: key),
              let value = Frequency(rawValue: raw)
        else { return .off }
        return value
    }

    public static func set(_ value: Frequency, in defaults: UserDefaults = .standard) {
        defaults.set(value.rawValue, forKey: key)
    }

    /// Round-24 slice T4.22: minimum gap (in days) between auto-backups.
    /// When at least one template has been archived, the store recommends
    /// a tighter cadence (7d) so the archive payload makes it into the
    /// next backup soon. Otherwise falls back to the user's chosen
    /// `Frequency`.
    public static func recommendedMinDays(
        defaults: UserDefaults = .standard
    ) -> Int {
        if !TemplateArchiveStore.archivedIDs(in: defaults).isEmpty {
            return 7
        }
        switch current(defaults: defaults) {
        case .off: return Int.max
        case .weekly: return 7
        case .daily: return 1
        }
    }
}
