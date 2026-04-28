import Foundation

/// Round-25 slice T4.28: pre-restore counts so the user can confirm
/// what they're about to overwrite. Caller decodes the snapshot first,
/// then renders these counts in a confirm sheet before invoking
/// `BackupService.restore(...)`.
public enum BackupRestorePreview {

    public struct Counts: Equatable, Sendable {
        public let templates: Int
        public let completions: Int
        public let hydration: Int
        public let housekeeping: Int
        public let trips: Int
        public let mood: Int
        public let archivedTemplates: Int
        public let housekeepingDayKeys: Int
        public let snapshotVersion: Int
        public let exportedAt: Date
    }

    public static func counts(from snapshot: BackupSnapshot) -> Counts {
        let logKeys: Int = (snapshot.housekeepingCompletionLog ?? [:])
            .values
            .map(\.count)
            .reduce(0, +)
        return Counts(
            templates: snapshot.templates.count,
            completions: snapshot.completions.count,
            hydration: snapshot.hydration.count,
            housekeeping: snapshot.housekeeping.count,
            trips: snapshot.trips.count,
            mood: snapshot.mood?.count ?? 0,
            archivedTemplates: snapshot.archivedTemplateIDs?.count ?? 0,
            housekeepingDayKeys: logKeys,
            snapshotVersion: snapshot.version,
            exportedAt: snapshot.exportedAt
        )
    }
}
