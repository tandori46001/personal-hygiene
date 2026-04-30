@testable import PersonalHygiene
@preconcurrency import XCTest

final class CurrencyRateChangeDetectorTests: XCTestCase {

    func test_evaluate_isStableWhenWithinThreshold() {
        let verdict = CurrencyRateChangeDetector.evaluate(previousRate: 1.0, currentRate: 1.005)
        XCTAssertEqual(verdict?.direction, .stable)
    }

    func test_evaluate_returnsUpForLargeIncrease() {
        let verdict = CurrencyRateChangeDetector.evaluate(previousRate: 1.0, currentRate: 1.05)
        XCTAssertEqual(verdict?.direction, .up)
        XCTAssertEqual(verdict?.percentDelta ?? 0, 0.05, accuracy: 0.001)
    }

    func test_evaluate_returnsDownForLargeDecrease() {
        let verdict = CurrencyRateChangeDetector.evaluate(previousRate: 1.0, currentRate: 0.95)
        XCTAssertEqual(verdict?.direction, .down)
    }

    func test_evaluate_nilForNonPositiveRates() {
        XCTAssertNil(CurrencyRateChangeDetector.evaluate(previousRate: 0, currentRate: 1.0))
        XCTAssertNil(CurrencyRateChangeDetector.evaluate(previousRate: 1.0, currentRate: -1))
    }

    func test_evaluate_customThreshold() {
        let withinDefault = CurrencyRateChangeDetector.evaluate(
            previousRate: 1.0,
            currentRate: 1.015
        )
        XCTAssertEqual(withinDefault?.direction, .stable)
        let triggeredAt1Pct = CurrencyRateChangeDetector.evaluate(
            previousRate: 1.0,
            currentRate: 1.015,
            threshold: 0.01
        )
        XCTAssertEqual(triggeredAt1Pct?.direction, .up)
    }
}
