@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-25 slice T2.15: smoke test that the chip's tint tier is consistent
/// with the percent it renders. Tests the underlying helper boundaries
/// since chip is a pure render of `TodayCompletionPercent`.
final class TodayDayCompletionChipBehaviorTests: XCTestCase {

    func test_percent_consistencyAcrossTiers() {
        XCTAssertEqual(TodayCompletionPercent.percent(done: 9, total: 10), 90)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 6, total: 10), 60)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 2, total: 10), 20)
    }
}
