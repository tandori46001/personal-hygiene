@testable import PersonalHygiene
import SwiftData
import XCTest

/// Round-23 slice T1.6 — guards that a v4 backup can be down-shifted by
/// stripping `moodWeeklyGoal` (simulating an older v3-era importer)
/// without losing any of the user-visible payloads. Mirrors the
/// round-12 `test_v11Backup_strippedToV1_keepsEveryUserVisibleItem` shape
/// so future schema bumps follow the same pattern.
@MainActor
final class BackupSnapshotV4DowngradeTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        MoodLogStore.clear()
        MoodWeeklyGoalStore.clear()
    }

    override func tearDown() async throws {
        MoodLogStore.clear()
        MoodWeeklyGoalStore.clear()
        container = nil
        try await super.tearDown()
    }

    func test_v4Backup_strippedOfGoal_decodesWithoutLosingMood() throws {
        MoodLogStore.record(.great, now: Date(timeIntervalSince1970: 1_700_000_000))
        MoodWeeklyGoalStore.setGoal(4)
        let v4 = try BackupService.export(from: container.mainContext)

        var json = try JSONSerialization.jsonObject(with: BackupService.encode(v4)) as? [String: Any] ?? [:]
        json.removeValue(forKey: "moodWeeklyGoal")
        let downgraded = try JSONSerialization.data(withJSONObject: json)

        let decoded = try BackupService.decode(downgraded)
        XCTAssertNil(decoded.moodWeeklyGoal)
        XCTAssertEqual(decoded.mood?.count, 1, "mood payload survives the goal strip")
    }

    func test_restore_v4StrippedOfGoal_preservesExistingGoal() throws {
        let v4 = try BackupService.export(from: container.mainContext)
        var json = try JSONSerialization.jsonObject(with: BackupService.encode(v4)) as? [String: Any] ?? [:]
        json.removeValue(forKey: "moodWeeklyGoal")
        let downgraded = try JSONSerialization.data(withJSONObject: json)

        MoodWeeklyGoalStore.setGoal(2)
        let decoded = try BackupService.decode(downgraded)
        try BackupService.restore(decoded, into: container.mainContext)

        XCTAssertEqual(MoodWeeklyGoalStore.goal(), 2,
                       "restore must not zap the user's current goal when payload is absent")
    }

    func test_v4Backup_handCraftedV3JSON_decodesAsNilGoal() throws {
        let json = """
        {
          "version": 3,
          "exportedAt": 1700000000.0,
          "templates": [],
          "completions": [],
          "hydration": [],
          "housekeeping": [],
          "trips": [],
          "mood": [{"mood": "great", "recordedAt": 1700000000.0}]
        }
        """
        let decoded = try BackupService.decode(Data(json.utf8))
        XCTAssertNil(decoded.moodWeeklyGoal)
        XCTAssertEqual(decoded.mood?.count, 1)
        XCTAssertEqual(decoded.version, 3)
    }
}
