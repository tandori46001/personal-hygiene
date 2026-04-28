@testable import PersonalHygiene
import XCTest

final class MoodWeeklyGoalStoreTests: XCTestCase {

    private let suite = "moodGoalTests-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_goal_defaultsToZero() {
        XCTAssertEqual(MoodWeeklyGoalStore.goal(in: defaults), 0)
        XCTAssertFalse(MoodWeeklyGoalStore.isActive(in: defaults))
    }

    func test_setGoal_persistsAndClamps() {
        MoodWeeklyGoalStore.setGoal(99, in: defaults)
        XCTAssertEqual(MoodWeeklyGoalStore.goal(in: defaults), 7)
        MoodWeeklyGoalStore.setGoal(-1, in: defaults)
        XCTAssertEqual(MoodWeeklyGoalStore.goal(in: defaults), 0)
    }

    func test_isActive_trueOnlyForPositiveGoal() {
        MoodWeeklyGoalStore.setGoal(0, in: defaults)
        XCTAssertFalse(MoodWeeklyGoalStore.isActive(in: defaults))
        MoodWeeklyGoalStore.setGoal(3, in: defaults)
        XCTAssertTrue(MoodWeeklyGoalStore.isActive(in: defaults))
    }
}
