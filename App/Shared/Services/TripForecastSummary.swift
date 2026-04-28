import Foundation

/// Round-23 slice T3.15: aggregates a list of `WeatherForecast` items into
/// a single trip-level summary (mean high/low + max rain probability) so
/// the TripDetail header can render a quick "expected weather" caption
/// without having to drill into the itinerary view.
public enum TripForecastSummary {

    public struct Summary: Equatable, Sendable {
        public let averageHighCelsius: Double
        public let averageLowCelsius: Double
        public let maxPrecipitationProbability: Double
    }

    public static func summarize(_ forecasts: [WeatherForecast]) -> Summary? {
        guard !forecasts.isEmpty else { return nil }
        let highs = forecasts.map(\.highCelsius)
        let lows = forecasts.map(\.lowCelsius)
        let maxRain = forecasts.map(\.precipitationProbability).max() ?? 0
        return Summary(
            averageHighCelsius: highs.reduce(0, +) / Double(highs.count),
            averageLowCelsius: lows.reduce(0, +) / Double(lows.count),
            maxPrecipitationProbability: maxRain
        )
    }
}
