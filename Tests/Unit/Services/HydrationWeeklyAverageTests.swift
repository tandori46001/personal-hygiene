@testable import PersonalHygiene
import XCTest

final class HydrationWeeklyAverageTests: XCTestCase {

    func test_emptyInput_zero() {
        XCTAssertEqual(HydrationWeeklyAverage.averageMilliliters(dailyTotals: []), 0)
    }

    func test_singleDay_returnsRoundedAmount() {
        let date = Date()
        let avg = HydrationWeeklyAverage.averageMilliliters(
            dailyTotals: [(date, 1234)]
        )
        XCTAssertEqual(avg, 1_230)
    }

    func test_sevenDays_average() {
        let date = Date()
        let totals = (0..<7).map { (date, $0 * 500) }
        // sum 0+500+1000+1500+2000+2500+3000 = 10500 / 7 = 1500
        XCTAssertEqual(
            HydrationWeeklyAverage.averageMilliliters(dailyTotals: totals),
            1_500
        )
    }
}
