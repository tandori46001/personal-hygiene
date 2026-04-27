import Foundation

/// Round-12 slice 12: configurable cache TTL for marine forecasts. Default is
/// 24h (matches `CachedMarineWeatherService.defaultTTLSeconds`); user can
/// pick 6h / 24h / 7d via Settings → Scheduling.
public enum MarineForecastFreshnessStore {

    public static let key = "marine.forecast.ttlHours"
    public static let defaultHours = 24
    public static let allowedHours = [6, 24, 24 * 7]

    public static func hours(defaults: UserDefaults = .standard) -> Int {
        let raw = defaults.integer(forKey: key)
        return allowedHours.contains(raw) ? raw : defaultHours
    }

    public static func ttlSeconds(defaults: UserDefaults = .standard) -> TimeInterval {
        TimeInterval(hours(defaults: defaults) * 3_600)
    }

    public static func set(_ value: Int, in defaults: UserDefaults = .standard) {
        guard allowedHours.contains(value) else { return }
        defaults.set(value, forKey: key)
    }
}
