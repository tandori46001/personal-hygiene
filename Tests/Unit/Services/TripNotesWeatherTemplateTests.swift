@testable import PersonalHygiene
@preconcurrency import XCTest

final class TripNotesWeatherTemplateTests: XCTestCase {

    private func forecast(high: Double, low: Double, rain: Double, daysFromNow: Int = 0) -> WeatherForecast {
        WeatherForecast(
            day: Date().addingTimeInterval(TimeInterval(daysFromNow) * 86_400),
            highCelsius: high,
            lowCelsius: low,
            precipitationProbability: rain,
            symbolName: "cloud"
        )
    }

    func test_body_emitsUnavailableLine_whenNoForecasts() {
        let body = TripNotesWeatherTemplate.body(
            for: [],
            headline: "## Weather",
            rainTag: "rain",
            unavailable: "no forecast"
        )
        XCTAssertTrue(body.contains("no forecast"))
    }

    func test_body_includesRainTagWhenChanceAtLeast30() {
        let body = TripNotesWeatherTemplate.body(
            for: [forecast(high: 22, low: 18, rain: 0.5)],
            headline: "## Weather",
            rainTag: "rain",
            unavailable: "no forecast"
        )
        XCTAssertTrue(body.contains("rain"))
        XCTAssertTrue(body.contains("50%"))
    }

    func test_body_omitsRainTagBelowThreshold() {
        let body = TripNotesWeatherTemplate.body(
            for: [forecast(high: 22, low: 18, rain: 0.1)],
            headline: "## Weather",
            rainTag: "rain",
            unavailable: "no forecast"
        )
        XCTAssertFalse(body.contains("rain"))
    }

    func test_body_includesHighLowDegrees() {
        let body = TripNotesWeatherTemplate.body(
            for: [forecast(high: 25.7, low: 17.2, rain: 0.0)],
            headline: "## Weather",
            rainTag: "rain",
            unavailable: "no forecast"
        )
        XCTAssertTrue(body.contains("26°/17°"))
    }
}
