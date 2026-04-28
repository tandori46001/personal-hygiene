@testable import PersonalHygiene
import XCTest

final class TodayCompletionPercentTests: XCTestCase {

    func test_percent_zeroWhenTotalIsZero() {
        XCTAssertEqual(TodayCompletionPercent.percent(done: 0, total: 0), 0)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 5, total: 0), 0)
    }

    func test_percent_roundsToNearest() {
        XCTAssertEqual(TodayCompletionPercent.percent(done: 1, total: 3), 33)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 2, total: 3), 67)
        XCTAssertEqual(TodayCompletionPercent.percent(done: 3, total: 3), 100)
    }

    func test_formatted_appendsPercentSign() {
        XCTAssertEqual(TodayCompletionPercent.formatted(done: 1, total: 4), "25%")
    }
}
