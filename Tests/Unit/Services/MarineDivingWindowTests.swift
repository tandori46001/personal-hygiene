@testable import PersonalHygiene
@preconcurrency import XCTest

final class MarineDivingWindowTests: XCTestCase {

    private func conditions(_ wave: Double, _ wind: Double, hourOffset: Int) -> MarineDivingWindow.HourlyConditions {
        MarineDivingWindow.HourlyConditions(
            hour: Date(timeIntervalSince1970: TimeInterval(hourOffset) * 3_600),
            waveHeightMeters: wave,
            windKnots: wind
        )
    }

    func test_bestWindow_nilForEmptyInput() {
        XCTAssertNil(MarineDivingWindow.bestWindow(in: []))
    }

    func test_bestWindow_pickedFromSingleContiguousRun() {
        let hours = [
            conditions(0.5, 8, hourOffset: 0),
            conditions(0.6, 9, hourOffset: 1),
            conditions(0.5, 7, hourOffset: 2),
        ]
        let window = MarineDivingWindow.bestWindow(in: hours)
        XCTAssertNotNil(window)
        XCTAssertEqual(window?.hours, 3)
    }

    func test_bestWindow_pickedFromLongestRun() {
        let hours = [
            conditions(0.5, 5, hourOffset: 0),
            conditions(2.0, 5, hourOffset: 1),
            conditions(0.5, 5, hourOffset: 2),
            conditions(0.6, 5, hourOffset: 3),
            conditions(0.5, 5, hourOffset: 4),
        ]
        let window = MarineDivingWindow.bestWindow(in: hours)
        XCTAssertEqual(window?.hours, 3, "second contiguous block (hours 2..4) wins over the lone hour 0")
    }

    func test_bestWindow_nilWhenAllHoursTooRough() {
        let hours = [
            conditions(2.0, 20, hourOffset: 0),
            conditions(2.5, 22, hourOffset: 1),
        ]
        XCTAssertNil(MarineDivingWindow.bestWindow(in: hours))
    }
}
