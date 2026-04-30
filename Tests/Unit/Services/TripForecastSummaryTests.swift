@testable import PersonalHygiene
@preconcurrency import XCTest

final class TripForecastSummaryTests: XCTestCase {

    private func forecast(high: Double, low: Double, rain: Double) -> WeatherForecast {
        WeatherForecast(
            day: Date(),
            highCelsius: high,
            lowCelsius: low,
            precipitationProbability: rain,
            symbolName: "sun.max"
        )
    }

    func test_summarize_returnsNilForEmpty() {
        XCTAssertNil(TripForecastSummary.summarize([]))
    }

    func test_summarize_averagesHighAndLow_picksMaxRain() {
        let forecasts = [
            forecast(high: 22, low: 16, rain: 0.1),
            forecast(high: 24, low: 18, rain: 0.6),
            forecast(high: 26, low: 20, rain: 0.3),
        ]
        let summary = TripForecastSummary.summarize(forecasts)
        XCTAssertEqual(summary?.averageHighCelsius ?? 0, 24, accuracy: 0.001)
        XCTAssertEqual(summary?.averageLowCelsius ?? 0, 18, accuracy: 0.001)
        XCTAssertEqual(summary?.maxPrecipitationProbability ?? 0, 0.6, accuracy: 0.001)
    }
}
