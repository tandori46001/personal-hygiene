@testable import PersonalHygiene
import XCTest

final class MoodLogStreakTests: XCTestCase {

    private let suite = "moodStreakTests-\(UUID().uuidString)"
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

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: 12
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    func test_streakDays_isZeroWithoutEntries() {
        XCTAssertEqual(
            MoodLogStore.streakDays(now: date(0), calendar: calendar(), defaults: defaults),
            0
        )
    }

    func test_streakDays_countsConsecutivePositiveDays() {
        for offset in 0..<5 {
            MoodLogStore.record(.good, now: date(-offset), in: defaults)
        }
        let streak = MoodLogStore.streakDays(now: date(0), calendar: calendar(), defaults: defaults)
        XCTAssertEqual(streak, 5)
    }

    func test_streakDays_breaksOnGapDay() {
        MoodLogStore.record(.good, now: date(0), in: defaults)
        MoodLogStore.record(.good, now: date(-1), in: defaults)
        // Skip day -2 entirely.
        MoodLogStore.record(.good, now: date(-3), in: defaults)
        XCTAssertEqual(
            MoodLogStore.streakDays(now: date(0), calendar: calendar(), defaults: defaults),
            2
        )
    }

    func test_streakDays_breaksOnBelowThresholdMood() {
        MoodLogStore.record(.good, now: date(0), in: defaults)
        MoodLogStore.record(.bad, now: date(-1), in: defaults)
        MoodLogStore.record(.good, now: date(-2), in: defaults)
        XCTAssertEqual(
            MoodLogStore.streakDays(now: date(0), calendar: calendar(), defaults: defaults),
            1
        )
    }

    func test_weeklyDelta_isPositiveWhenThisWeekIsHappier() {
        for offset in 0..<7 {
            MoodLogStore.record(.great, now: date(-offset), in: defaults)
        }
        for offset in 7..<14 {
            MoodLogStore.record(.bad, now: date(-offset), in: defaults)
        }
        let entries = MoodLogStore.entries(defaults: defaults)
        let delta = MoodTrendAggregator.weeklyDelta(from: entries, endingAt: date(0), calendar: calendar())
        XCTAssertNotNil(delta)
        XCTAssertGreaterThan(delta ?? 0, 0)
    }
}
