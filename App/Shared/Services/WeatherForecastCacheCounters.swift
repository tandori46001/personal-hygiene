import Foundation

/// Round-23 slice T6.33: process-local hit/miss counters for the weather
/// forecast cache. Diagnostics view surfaces these so the user can spot a
/// cache that's never warming up (would imply WeatherKit always failing).
public final class WeatherForecastCacheCounters: @unchecked Sendable {

    public static let shared = WeatherForecastCacheCounters()

    private(set) var hits = 0
    private(set) var misses = 0
    private let lock = NSLock()

    public init() {}

    public func recordHit() {
        lock.lock(); defer { lock.unlock() }
        hits += 1
    }

    public func recordMiss() {
        lock.lock(); defer { lock.unlock() }
        misses += 1
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        hits = 0
        misses = 0
    }

    public var snapshot: (hits: Int, misses: Int) {
        lock.lock(); defer { lock.unlock() }
        return (hits, misses)
    }
}
