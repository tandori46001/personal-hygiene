@preconcurrency import XCTest

@testable import PersonalHygiene

final class BedtimeCalculatorTests: XCTestCase {

    func test_bedtime_for7amWakeUp_isPreviousDay2315() {
        // 07:00 - 7h45m = 23:15 the previous evening (1395 minutes-from-midnight)
        let result = BedtimeCalculator.bedtimeMinutes(forWakeUp: 7 * 60)
        XCTAssertEqual(result, 23 * 60 + 15)
    }

    func test_bedtime_for8amWakeUp_is0015() {
        // 08:00 - 7h45m wraps to 00:15
        let result = BedtimeCalculator.bedtimeMinutes(forWakeUp: 8 * 60)
        XCTAssertEqual(result, 15)
    }

    func test_bedtime_customSleepTarget() {
        // 06:00 wake, 8h target → 22:00 bedtime
        let result = BedtimeCalculator.bedtimeMinutes(
            forWakeUp: 6 * 60,
            sleepTarget: 8 * 60
        )
        XCTAssertEqual(result, 22 * 60)
    }

    func test_bedtime_isAlwaysWithinDay() {
        for wakeUp in stride(from: 0, to: 24 * 60, by: 30) {
            let result = BedtimeCalculator.bedtimeMinutes(forWakeUp: wakeUp)
            XCTAssertGreaterThanOrEqual(result, 0)
            XCTAssertLessThan(result, 24 * 60)
        }
    }

    func test_deficit_positiveWhenSleepShorterThanTarget() {
        XCTAssertEqual(
            BedtimeCalculator.deficit(actualMinutes: 6 * 60),
            BedtimeCalculator.defaultSleepTargetMinutes - 6 * 60
        )
    }

    func test_deficit_negativeWhenSleepLongerThanTarget() {
        XCTAssertEqual(
            BedtimeCalculator.deficit(actualMinutes: 9 * 60),
            BedtimeCalculator.defaultSleepTargetMinutes - 9 * 60
        )
    }
}
