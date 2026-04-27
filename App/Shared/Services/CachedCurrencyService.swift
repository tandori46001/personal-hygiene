import Foundation

/// Caches the per-unit `rate` from a `CurrencyService` per (from, to) currency
/// pair for `ttl` seconds. The amount is applied locally on cache hits so
/// changing the slider doesn't trigger a network round-trip.
public final class CachedCurrencyService: CurrencyService, @unchecked Sendable {

    public static let defaultTTL: TimeInterval = 30 * 60

    private struct Entry {
        let rate: Double
        let storedAt: Date
    }

    private let upstream: any CurrencyService
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private let lock = NSLock()
    private var cache: [String: Entry] = [:]

    public init(
        upstream: any CurrencyService,
        ttl: TimeInterval = CachedCurrencyService.defaultTTL,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.upstream = upstream
        self.ttl = ttl
        self.now = now
    }

    public func convert(amount: Double, from: String, to: String) async throws -> CurrencyConversion {
        let key = Self.cacheKey(from: from, to: to)
        let timestamp = now()
        if let rate = lookup(key: key, at: timestamp) {
            return CurrencyConversion(
                from: from.uppercased(),
                to: to.uppercased(),
                rate: rate,
                amountConverted: rate * amount
            )
        }
        let result = try await upstream.convert(amount: amount, from: from, to: to)
        store(rate: result.rate, key: key, at: timestamp)
        return result
    }

    /// Round-11: pass-through to upstream + populate per-target cache. We
    /// always hit the network for the multi-target call (single round-trip is
    /// cheap; partial cache hits would require recomposing the response).
    public func convertAll(
        amount: Double,
        from: String,
        to targets: [String]
    ) async throws -> [CurrencyConversion] {
        let results = try await upstream.convertAll(amount: amount, from: from, to: targets)
        let timestamp = now()
        for result in results {
            store(rate: result.rate, key: Self.cacheKey(from: result.from, to: result.to), at: timestamp)
        }
        return results
    }

    private func lookup(key: String, at instant: Date) -> Double? {
        lock.lock(); defer { lock.unlock() }
        guard let entry = cache[key] else { return nil }
        if instant.timeIntervalSince(entry.storedAt) > ttl { return nil }
        return entry.rate
    }

    private func store(rate: Double, key: String, at instant: Date) {
        lock.lock(); defer { lock.unlock() }
        cache[key] = Entry(rate: rate, storedAt: instant)
    }

    static func cacheKey(from: String, to: String) -> String {
        "\(from.uppercased())→\(to.uppercased())"
    }
}
