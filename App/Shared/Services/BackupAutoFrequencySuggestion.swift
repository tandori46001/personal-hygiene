import Foundation

/// Round-25 slice T4.27: pure helper that decides when to surface the
/// "you haven't backed up in a while" banner on Settings. Pulls last-
/// recorded backup timestamp from `MostRecentBackupStore` and returns
/// true when the gap exceeds the recommendation.
public enum BackupAutoFrequencySuggestion {

    public static func shouldSurfaceBanner(
        lastBackupAt: Date? = MostRecentBackupStore.recordedAt(),
        recommendedDays: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard let lastBackupAt else { return true }
        let gap = calendar.dateComponents([.day], from: lastBackupAt, to: now).day ?? 0
        return gap >= recommendedDays
    }

    public static func daysSinceLastBackup(
        lastBackupAt: Date? = MostRecentBackupStore.recordedAt(),
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int? {
        guard let lastBackupAt else { return nil }
        return calendar.dateComponents([.day], from: lastBackupAt, to: now).day
    }
}
