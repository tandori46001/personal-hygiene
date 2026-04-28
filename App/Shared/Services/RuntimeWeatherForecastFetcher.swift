import Foundation

/// Round-23 slice T3.13: runtime-aware factory that returns a real
/// WeatherKit-backed fetcher when the SDK is available + iOS 16+ is the
/// runtime. Falls back to `StubWeatherForecastService` so the surface
/// continues to compile + behave deterministically without entitlement.
public enum RuntimeWeatherForecastFetcher {

    public static func make() -> any WeatherForecastFetching {
        #if canImport(WeatherKit) && !os(watchOS)
        if #available(iOS 16.0, *) {
            return WeatherKitForecastService()
        }
        #endif
        return StubWeatherForecastService()
    }
}
