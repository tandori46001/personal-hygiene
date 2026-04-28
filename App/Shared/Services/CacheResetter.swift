import Foundation

/// Round-23 slice T6.34: clears every UserDefaults-backed transient cache
/// the app maintains. Surfaced in Settings as a destructive "Reset all
/// caches" button. Does NOT touch SwiftData — that's a separate destructive
/// path inside the backup-restore flow.
public enum CacheResetter {

    public static func resetAll(in defaults: UserDefaults = .standard) {
        // Round-21+: weather forecast cache lives in App Group.
        let appGroup = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
        // Best-effort sweep of every weather-forecast key.
        for key in appGroup.dictionaryRepresentation().keys
        where key.hasPrefix("weatherForecast.") {
            appGroup.removeObject(forKey: key)
        }
        // Round-22 cache counters.
        WeatherForecastCacheCounters.shared.reset()
        // Round-21 last-conversion store + recent-conversions store.
        defaults.removeObject(forKey: "currency.lastConversion.v1")
        defaults.removeObject(forKey: "currency.recentConversions.v1")
        // Round-22 watch hydration pending taps (queue, not audit).
        WatchHydrationGlanceStore.clearPending(in: appGroup)
        // Round-13 marine forecast freshness window — left untouched here
        // because it's load-bearing for stale-forecast detection.
    }
}
