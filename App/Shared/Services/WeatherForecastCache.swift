import Foundation

/// Round-21 slice T3.14: short-TTL cache for `WeatherForecast` results keyed
/// by `(latRounded, lonRounded)`. Lives in the App Group so iPhone + Watch
/// share the same forecast snapshot, mirroring how marine forecast results
/// are cached.
public final class WeatherForecastCache: @unchecked Sendable {

    public static let shared = WeatherForecastCache()
    public static let defaultTTLSeconds: TimeInterval = 6 * 60 * 60

    private let defaults: UserDefaults
    private let ttl: TimeInterval

    public init(
        defaults: UserDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard,
        ttl: TimeInterval = WeatherForecastCache.defaultTTLSeconds
    ) {
        self.defaults = defaults
        self.ttl = ttl
    }

    public struct Entry: Codable, Sendable {
        public let storedAt: Date
        public let forecasts: [WeatherForecast]
    }

    public func key(latitude: Double, longitude: Double) -> String {
        let latPart = String(format: "%.2f", latitude)
        let lonPart = String(format: "%.2f", longitude)
        return "weatherForecast.\(latPart),\(lonPart)"
    }

    public func cached(latitude: Double, longitude: Double, now: Date = Date()) -> [WeatherForecast]? {
        let storeKey = key(latitude: latitude, longitude: longitude)
        guard let data = defaults.data(forKey: storeKey),
              let entry = try? JSONDecoder().decode(Entry.self, from: data)
        else {
            // Round-23 slice T6.33: counters used by Diagnostics.
            WeatherForecastCacheCounters.shared.recordMiss()
            return nil
        }
        if now.timeIntervalSince(entry.storedAt) > ttl {
            WeatherForecastCacheCounters.shared.recordMiss()
            return nil
        }
        WeatherForecastCacheCounters.shared.recordHit()
        return entry.forecasts
    }

    /// Round-22 slice T3.18: read the cache without TTL — used when the
    /// network is unreachable so the user still sees the most-recent
    /// forecast with a "stale" badge instead of nothing.
    public func cachedIgnoringTTL(latitude: Double, longitude: Double) -> Entry? {
        let storeKey = key(latitude: latitude, longitude: longitude)
        guard let data = defaults.data(forKey: storeKey),
              let entry = try? JSONDecoder().decode(Entry.self, from: data)
        else { return nil }
        return entry
    }

    public func store(_ forecasts: [WeatherForecast], latitude: Double, longitude: Double, now: Date = Date()) {
        let entry = Entry(storedAt: now, forecasts: forecasts)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        defaults.set(data, forKey: key(latitude: latitude, longitude: longitude))
    }

    public func clear(latitude: Double, longitude: Double) {
        defaults.removeObject(forKey: key(latitude: latitude, longitude: longitude))
    }
}
