import Foundation

/// Round-25 slice T5.35: pure picker that, given the live forecast cache
/// + a target itinerary day, returns the freshest matching cached entry
/// even when the day is outside the cache's primary window. Used by
/// `ItineraryView` so the chip doesn't blank out on a bad network.
public enum ItineraryDayWeatherFallback {

    public static func bestForecast(
        forDay target: Date,
        cache: [WeatherForecast],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> WeatherForecast? {
        guard !cache.isEmpty else { return nil }
        let targetDay = calendar.startOfDay(for: target)

        if let exactMatch = cache.first(where: {
            calendar.startOfDay(for: $0.day) == targetDay
        }) {
            return exactMatch
        }

        return cache.min(by: { lhs, rhs in
            let lhsDelta = abs(calendar.startOfDay(for: lhs.day).timeIntervalSince(targetDay))
            let rhsDelta = abs(calendar.startOfDay(for: rhs.day).timeIntervalSince(targetDay))
            return lhsDelta < rhsDelta
        })
    }
}
