import Foundation

/// Round-21 slice T3.13: lightweight value type representing a single day's
/// forecast for a trip itinerary day. Independent of the WeatherKit SDK so
/// the rest of the app can hold/serialize forecasts without a hard dep.
public struct WeatherForecast: Codable, Equatable, Sendable {

    public let day: Date
    public let highCelsius: Double
    public let lowCelsius: Double
    /// 0…1 probability of precipitation across the day.
    public let precipitationProbability: Double
    /// Iconography hint: SF Symbol name. Caller maps this to a system image.
    public let symbolName: String

    public init(
        day: Date,
        highCelsius: Double,
        lowCelsius: Double,
        precipitationProbability: Double,
        symbolName: String
    ) {
        self.day = day
        self.highCelsius = highCelsius
        self.lowCelsius = lowCelsius
        self.precipitationProbability = max(0, min(1, precipitationProbability))
        self.symbolName = symbolName
    }
}

/// Abstraction over the platform forecast service so trips can be unit-tested
/// without WeatherKit entitlement on simulator. `WeatherKitForecastService`
/// fulfills this on real devices; `StubWeatherForecastService` returns canned
/// data for previews + tests.
public protocol WeatherForecastFetching: Sendable {
    func forecast(latitude: Double, longitude: Double, days: Int) async throws -> [WeatherForecast]
}

public struct StubWeatherForecastService: WeatherForecastFetching {

    public init() {}

    public func forecast(latitude: Double, longitude: Double, days: Int) async throws -> [WeatherForecast] {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        return (0..<max(0, days)).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return WeatherForecast(
                day: day,
                highCelsius: 24,
                lowCelsius: 18,
                precipitationProbability: 0.1,
                symbolName: "sun.max"
            )
        }
    }
}
