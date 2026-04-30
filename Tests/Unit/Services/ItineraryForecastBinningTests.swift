@testable import PersonalHygiene
@preconcurrency import XCTest

final class ItineraryForecastBinningTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int, hour: Int = 12) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 6, day: 1, hour: hour
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    private func forecast(daysFromBase: Int, high: Double = 22) -> WeatherForecast {
        WeatherForecast(
            day: date(daysFromBase),
            highCelsius: high,
            lowCelsius: 16,
            precipitationProbability: 0.1,
            symbolName: "sun.max"
        )
    }

    func test_bin_keysByCalendarStartOfDay() {
        let inputs = [forecast(daysFromBase: 0), forecast(daysFromBase: 1)]
        let bins = ItineraryForecastBinning.bin(inputs, calendar: calendar())
        XCTAssertEqual(bins.count, 2)
        let key = calendar().startOfDay(for: date(0))
        XCTAssertNotNil(bins[key])
    }

    func test_bin_lastWriteWins_whenMultipleForecastsForSameDay() {
        let early = forecast(daysFromBase: 0, high: 18)
        let late = WeatherForecast(
            day: date(0, hour: 23),
            highCelsius: 25,
            lowCelsius: 16,
            precipitationProbability: 0,
            symbolName: "sun.max"
        )
        let bins = ItineraryForecastBinning.bin([early, late], calendar: calendar())
        XCTAssertEqual(bins.count, 1)
        let key = calendar().startOfDay(for: date(0))
        XCTAssertEqual(bins[key]?.highCelsius, 25)
    }

    func test_daysSpanned_clampsBetween1And10() {
        XCTAssertEqual(ItineraryForecastBinning.daysSpanned(from: date(0), to: date(0), calendar: calendar()), 1)
        XCTAssertEqual(ItineraryForecastBinning.daysSpanned(from: date(0), to: date(2), calendar: calendar()), 3)
        XCTAssertEqual(ItineraryForecastBinning.daysSpanned(from: date(0), to: date(20), calendar: calendar()), 10,
                       "a 20-day voyage clamps to WeatherKit's 10-day horizon")
        XCTAssertEqual(ItineraryForecastBinning.daysSpanned(from: date(5), to: date(0), calendar: calendar()), 1,
                       "negative deltas clamp to 1")
    }

    func test_forecast_returnsNilForOutOfRangeIndex() {
        let bins = ItineraryForecastBinning.bin([forecast(daysFromBase: 0)], calendar: calendar())
        XCTAssertNil(
            ItineraryForecastBinning.forecast(
                forIndex: 5,
                tripStart: date(0),
                in: bins,
                calendar: calendar()
            )
        )
    }
}
