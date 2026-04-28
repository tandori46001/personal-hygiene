import Foundation

#if canImport(WeatherKit) && !os(watchOS)
import CoreLocation
import WeatherKit

/// Round-21 slice T3.13: bridges Apple WeatherKit into the
/// `WeatherForecastFetching` protocol so itinerary days can render a real
/// forecast chip when the entitlement ships. Until then, the host app
/// continues to inject `StubWeatherForecastService` (no entitlement → no
/// network call).
@available(iOS 16.0, *)
public struct WeatherKitForecastService: WeatherForecastFetching {

    public init() {}

    public func forecast(latitude: Double, longitude: Double, days: Int) async throws -> [WeatherForecast] {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let service = WeatherService.shared
        let dailyForecast = try await service.weather(for: location, including: .daily)
        return dailyForecast.forecast.prefix(max(0, days)).map { day in
            WeatherForecast(
                day: day.date,
                highCelsius: day.highTemperature.converted(to: .celsius).value,
                lowCelsius: day.lowTemperature.converted(to: .celsius).value,
                precipitationProbability: day.precipitationChance,
                symbolName: day.symbolName
            )
        }
    }
}
#endif
