@testable import PersonalHygiene
import XCTest

final class HydrationGoalReachedHapticTests: XCTestCase {

    private let suite = "hydrationHaptic-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

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

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(
            calendar: calendar(), timeZone: TimeZone(secondsFromGMT: 0),
            year: year, month: month, day: day
        ).date!
    }

    func test_shouldPlay_falseWhenBelowGoal() {
        XCTAssertFalse(HydrationGoalReachedHaptic.shouldPlay(
            currentTotalMl: 500,
            goalMl: 1000,
            now: date(year: 2026, month: 4, day: 28),
            calendar: calendar(),
            in: defaults
        ))
    }

    func test_shouldPlay_trueOnFirstReach() {
        XCTAssertTrue(HydrationGoalReachedHaptic.shouldPlay(
            currentTotalMl: 1000,
            goalMl: 1000,
            now: date(year: 2026, month: 4, day: 28),
            calendar: calendar(),
            in: defaults
        ))
    }

    func test_shouldPlay_falseAfterRecordedToday() {
        HydrationGoalReachedHaptic.recordPlayed(
            now: date(year: 2026, month: 4, day: 28),
            calendar: calendar(),
            in: defaults
        )
        XCTAssertFalse(HydrationGoalReachedHaptic.shouldPlay(
            currentTotalMl: 1500,
            goalMl: 1000,
            now: date(year: 2026, month: 4, day: 28),
            calendar: calendar(),
            in: defaults
        ))
    }

    func test_shouldPlay_resetsOnNextDay() {
        HydrationGoalReachedHaptic.recordPlayed(
            now: date(year: 2026, month: 4, day: 28),
            calendar: calendar(),
            in: defaults
        )
        XCTAssertTrue(HydrationGoalReachedHaptic.shouldPlay(
            currentTotalMl: 1000,
            goalMl: 1000,
            now: date(year: 2026, month: 4, day: 29),
            calendar: calendar(),
            in: defaults
        ))
    }
}
