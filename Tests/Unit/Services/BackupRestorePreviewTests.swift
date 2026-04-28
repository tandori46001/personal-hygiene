@testable import PersonalHygiene
import XCTest

final class BackupRestorePreviewTests: XCTestCase {

    func test_counts_zeroForEmptySnapshot() {
        let snapshot = BackupSnapshot(
            templates: [],
            completions: [],
            hydration: [],
            housekeeping: [],
            trips: []
        )
        let counts = BackupRestorePreview.counts(from: snapshot)
        XCTAssertEqual(counts.templates, 0)
        XCTAssertEqual(counts.completions, 0)
        XCTAssertEqual(counts.archivedTemplates, 0)
        XCTAssertEqual(counts.housekeepingDayKeys, 0)
        XCTAssertGreaterThanOrEqual(counts.snapshotVersion, 6)
    }

    func test_counts_sumsHousekeepingDayKeysAcrossRooms() {
        let snapshot = BackupSnapshot(
            templates: [],
            completions: [],
            hydration: [],
            housekeeping: [],
            trips: [],
            housekeepingCompletionLog: [
                "kitchen": ["2026-04-25", "2026-04-26"],
                "bathroom": ["2026-04-27"],
            ]
        )
        let counts = BackupRestorePreview.counts(from: snapshot)
        XCTAssertEqual(counts.housekeepingDayKeys, 3)
    }

    func test_counts_archivedTemplatesReflectsSnapshotField() {
        let snapshot = BackupSnapshot(
            templates: [],
            completions: [],
            hydration: [],
            housekeeping: [],
            trips: [],
            archivedTemplateIDs: [UUID(), UUID(), UUID()]
        )
        XCTAssertEqual(BackupRestorePreview.counts(from: snapshot).archivedTemplates, 3)
    }
}
