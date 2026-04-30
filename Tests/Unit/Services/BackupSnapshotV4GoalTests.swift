@testable import PersonalHygiene
import SwiftData
@preconcurrency import XCTest

@MainActor
final class BackupSnapshotV4GoalTests: XCTestCase {

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

    func test_export_includesGoalWhenSet() throws {
        MoodWeeklyGoalStore.setGoal(4)
        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertEqual(snapshot.moodWeeklyGoal, 4)
        // Round 24 bumped version to 5 (added archivedTemplateIDs).
        XCTAssertGreaterThanOrEqual(snapshot.version, 4)
    }

    func test_export_omitsGoalWhenInactive() throws {
        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertNil(snapshot.moodWeeklyGoal)
    }

    func test_restore_replaysGoalIntoStore() throws {
        MoodWeeklyGoalStore.setGoal(5)
        let snapshot = try BackupService.export(from: container.mainContext)
        MoodWeeklyGoalStore.clear()
        XCTAssertEqual(MoodWeeklyGoalStore.goal(), 0)

        try BackupService.restore(snapshot, into: container.mainContext)

        XCTAssertEqual(MoodWeeklyGoalStore.goal(), 5)
    }

    func test_restore_v3BackupWithoutGoalLeavesExistingValueAlone() throws {
        let json = """
        {
          "version": 3,
          "exportedAt": 1700000000.0,
          "templates": [],
          "completions": [],
          "hydration": [],
          "housekeeping": [],
          "trips": []
        }
        """
        MoodWeeklyGoalStore.setGoal(3)
        let decoded = try BackupService.decode(Data(json.utf8))
        XCTAssertNil(decoded.moodWeeklyGoal)
        try BackupService.restore(decoded, into: container.mainContext)
        XCTAssertEqual(MoodWeeklyGoalStore.goal(), 3)
    }
}
