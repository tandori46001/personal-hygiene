import Foundation

/// Round-23 slice T1.5: pure binning helper extracted from `ItineraryView`
/// so unit tests can pin down the day-key grouping behaviour without
/// driving the SwiftUI surface. The view delegates here for both the
/// round-22 cache path and the round-22 fetch path.
public enum ItineraryForecastBinning {

    public static func bin(
        _ forecasts: [WeatherForecast],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Date: WeatherForecast] {
        var result: [Date: WeatherForecast] = [:]
        for forecast in forecasts {
            result[calendar.startOfDay(for: forecast.day)] = forecast
        }
        return result
    }

    /// Trip span in days, inclusive of both endpoints, clamped to [1, 10]
    /// so a multi-week voyage doesn't blow past WeatherKit's daily horizon.
    public static func daysSpanned(
        from startDate: Date,
        to endDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let delta = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, min(10, delta + 1))
    }

    /// Lookup the forecast for itinerary day `index` against `tripStart`.
    public static func forecast(
        forIndex index: Int,
        tripStart: Date,
        in bins: [Date: WeatherForecast],
        calendar: Calendar = .autoupdatingCurrent
    ) -> WeatherForecast? {
        guard let day = calendar.date(byAdding: .day, value: index, to: tripStart) else {
            return nil
        }
        return bins[calendar.startOfDay(for: day)]
    }
}
