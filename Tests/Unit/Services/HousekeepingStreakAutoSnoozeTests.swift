@testable import PersonalHygiene
import XCTest

final class HousekeepingStreakAutoSnoozeTests: XCTestCase {

    func test_below7Days_noSnoozeSuggested() {
        XCTAssertEqual(HousekeepingStreakAutoSnooze.suggestedSnoozeDays(currentStreak: 0), 0)
        XCTAssertEqual(HousekeepingStreakAutoSnooze.suggestedSnoozeDays(currentStreak: 6), 0)
    }

    func test_at7Days_yields3DaySnooze() {
        XCTAssertEqual(HousekeepingStreakAutoSnooze.suggestedSnoozeDays(currentStreak: 7), 3)
    }

    func test_longerStreak_scalesUpToWeeklyCap() {
        XCTAssertEqual(HousekeepingStreakAutoSnooze.suggestedSnoozeDays(currentStreak: 14), 6)
        XCTAssertEqual(HousekeepingStreakAutoSnooze.suggestedSnoozeDays(currentStreak: 30), 7,
                       "capped at one week")
    }

    func test_snoozedUntil_returnsNilForBelowThresholdStreak() {
        XCTAssertNil(HousekeepingStreakAutoSnooze.snoozedUntil(
            currentStreak: 3,
            from: Date()
        ))
    }
}
