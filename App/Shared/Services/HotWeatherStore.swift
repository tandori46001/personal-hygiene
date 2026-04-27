import Foundation

/// Round-12 slice 31: when the user enables "Hot weather mode", hydration
/// reminders bump the daily goal by a fixed amount (default +500ml). Stored
/// as a single boolean toggle + the bump in millilitres for simplicity. We
/// do not auto-detect temperature here — the toggle is manual; future work
/// could wire it to WeatherKit's daily forecast.
public enum HotWeatherStore {

    public static let enabledKey = "hydration.hotWeather.enabled"
    public static let bumpKey = "hydration.hotWeather.bumpMilliliters"
    public static let defaultBumpMilliliters = 500

    public static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    public static func setEnabled(_ value: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: enabledKey)
    }

    public static func bumpMilliliters(defaults: UserDefaults = .standard) -> Int {
        let raw = defaults.integer(forKey: bumpKey)
        return raw > 0 ? raw : defaultBumpMilliliters
    }

    public static func setBumpMilliliters(_ value: Int, in defaults: UserDefaults = .standard) {
        defaults.set(max(0, value), forKey: bumpKey)
    }

    /// Apply the bump to a base goal. When disabled returns `base` unchanged.
    public static func adjusted(base: Int, defaults: UserDefaults = .standard) -> Int {
        guard isEnabled(defaults: defaults) else { return base }
        return base + bumpMilliliters(defaults: defaults)
    }
}
