import XCTest

@testable import PersonalHygiene

final class WidgetReloadCounterTests: XCTestCase {

    func test_increment_addsOnePerCall() {
        let counter = WidgetReloadCounter()
        XCTAssertEqual(counter.count, 0)
        counter.increment()
        counter.increment()
        counter.increment()
        XCTAssertEqual(counter.count, 3)
    }

    func test_increment_recordsLastFiredAt() {
        let counter = WidgetReloadCounter()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        counter.increment(at: when)
        XCTAssertEqual(counter.lastFiredAt, when)
    }

    func test_reset_zeroesCountAndClearsTimestamp() {
        let counter = WidgetReloadCounter()
        counter.increment()
        counter.increment()
        counter.reset()
        XCTAssertEqual(counter.count, 0)
        XCTAssertNil(counter.lastFiredAt)
    }
}
