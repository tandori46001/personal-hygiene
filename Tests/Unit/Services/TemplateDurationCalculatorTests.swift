@testable import PersonalHygiene
import XCTest

final class TemplateDurationCalculatorTests: XCTestCase {

    private func makeBlock(duration: Int) -> Block {
        Block(
            title: "X",
            category: .work,
            startMinutesFromMidnight: 0,
            durationMinutes: duration
        )
    }

    func test_totalMinutes_emptyZero() {
        XCTAssertEqual(TemplateDurationCalculator.totalMinutes([]), 0)
    }

    func test_totalMinutes_sumsDurations() {
        let blocks = [makeBlock(duration: 30), makeBlock(duration: 45), makeBlock(duration: 60)]
        XCTAssertEqual(TemplateDurationCalculator.totalMinutes(blocks), 135)
    }

    func test_totalMinutes_clampsNegative() {
        let blocks = [makeBlock(duration: 30), makeBlock(duration: -10)]
        XCTAssertEqual(TemplateDurationCalculator.totalMinutes(blocks), 30)
    }

    func test_formatted_zero() {
        XCTAssertEqual(TemplateDurationCalculator.formatted(0), "0m")
    }

    func test_formatted_minutesOnly() {
        XCTAssertEqual(TemplateDurationCalculator.formatted(45), "45m")
    }

    func test_formatted_hoursOnly() {
        XCTAssertEqual(TemplateDurationCalculator.formatted(120), "2h")
    }

    func test_formatted_hoursAndMinutes() {
        XCTAssertEqual(TemplateDurationCalculator.formatted(135), "2h 15m")
    }
}
