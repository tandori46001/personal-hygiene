@testable import PersonalHygiene
import XCTest

final class ItineraryDayWeatherFallbackTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    private func forecast(_ daysFromBase: Int) -> WeatherForecast {
        WeatherForecast(
            day: date(daysFromBase),
            highCelsius: 25,
            lowCelsius: 18,
            precipitationProbability: 0.1,
            symbolName: "sun.max"
        )
    }

    func test_bestForecast_nilWhenCacheEmpty() {
        XCTAssertNil(ItineraryDayWeatherFallback.bestForecast(
            forDay: date(0),
            cache: [],
            calendar: calendar()
        ))
    }

    func test_bestForecast_picksExactDayMatch() {
        let cache = [forecast(-1), forecast(0), forecast(1)]
        let pick = ItineraryDayWeatherFallback.bestForecast(
            forDay: date(0),
            cache: cache,
            calendar: calendar()
        )
        XCTAssertEqual(pick?.day, date(0))
    }

    func test_bestForecast_picksClosestWhenNoExactMatch() {
        let cache = [forecast(-3), forecast(2)]
        let pick = ItineraryDayWeatherFallback.bestForecast(
            forDay: date(0),
            cache: cache,
            calendar: calendar()
        )
        XCTAssertEqual(pick?.day, date(2))
    }
}
