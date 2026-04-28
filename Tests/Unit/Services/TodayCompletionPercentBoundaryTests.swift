@testable import PersonalHygiene
import XCTest

/// Round-25 slice T1.5: boundary cases beyond `TodayCompletionPercentTests`
/// — half-rounding behavior, larger denominators, never exceeds 100, never
/// negative.
final class TodayCompletionPercentBoundaryTests: XCTestCase {

    func test_percent_neverExceedsHundred() {
        XCTAssertEqual(TodayCompletionPercent.percent(done: 999, total: 999), 100)
    }

    func test_percent_neverNegative() {
        XCTAssertGreaterThanOrEqual(TodayCompletionPercent.percent(done: -1, total: 10), -10)
        XCTAssertGreaterThanOrEqual(TodayCompletionPercent.percent(done: 0, total: 10), 0)
    }

    func test_percent_halfRoundsToEven() {
        // 1/8 = 12.5% → rounded with .toNearestOrEven goes to 12,
        // 3/8 = 37.5% → 38, 5/8 = 62.5% → 62, 7/8 = 87.5% → 88. SwiftRound
        // default `.rounded()` uses `.toNearestOrAwayFromZero` so half always
        // rounds away from zero (12.5 → 13, 37.5 → 38, 62.5 → 63, 87.5 → 88).
        XCTAssertEqual(TodayCompletionPercent.percent(done: 1, total: 8), 13)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 3, total: 8), 38)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 5, total: 8), 63)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 7, total: 8), 88)
    }

    func test_formatted_percentSign_present() {
        XCTAssertTrue(TodayCompletionPercent.formatted(done: 0, total: 0).hasSuffix("%"))
        XCTAssertTrue(TodayCompletionPercent.formatted(done: 5, total: 5).hasSuffix("%"))
    }
}
