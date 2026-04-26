import Foundation

/// Caches `MarineWeatherService` responses per (lat, lon) for `ttl` seconds so
/// repeatedly opening the marine view doesn't re-hit Open-Meteo on every appear.
/// Marine conditions change slowly enough that a 30-minute TTL is plenty.
public final class CachedMarineWeatherService: MarineWeatherService, @unchecked Sendable {

    public static let defaultTTL: TimeInterval = 30 * 60

    private struct Entry {
        let conditions: MarineConditions
        let storedAt: Date
    }

    private let upstream: any MarineWeatherService
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private let lock = NSLock()
    private var cache: [String: Entry] = [:]

    public init(
        upstream: any MarineWeatherService,
        ttl: TimeInterval = CachedMarineWeatherService.defaultTTL,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.upstream = upstream
        self.ttl = ttl
        self.now = now
    }

    public func current(at latitude: Double, longitude: Double) async throws -> MarineConditions {
        let key = Self.cacheKey(latitude: latitude, longitude: longitude)
        let timestamp = now()
        if let cached = lookup(key: key, at: timestamp) {
            return cached
        }
        let fresh = try await upstream.current(at: latitude, longitude: longitude)
        store(fresh, key: key, at: timestamp)
        return fresh
    }

    private func lookup(key: String, at instant: Date) -> MarineConditions? {
        lock.lock(); defer { lock.unlock() }
        guard let entry = cache[key] else { return nil }
        if instant.timeIntervalSince(entry.storedAt) > ttl { return nil }
        return entry.conditions
    }

    private func store(_ conditions: MarineConditions, key: String, at instant: Date) {
        lock.lock(); defer { lock.unlock() }
        cache[key] = Entry(conditions: conditions, storedAt: instant)
    }

    static func cacheKey(latitude: Double, longitude: Double) -> String {
        // Round to 4 decimals (~11 m). Avoids cache misses from FP drift while
        // still being precise enough for marine conditions, which vary by km.
        String(format: "%.4f,%.4f", latitude, longitude)
    }
}
