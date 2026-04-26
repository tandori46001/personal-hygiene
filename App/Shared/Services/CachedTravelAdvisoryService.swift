import Foundation

/// Memoizes `TravelAdvisoryService` lookups so opening multiple trips to the
/// same destination does not rebuild the URL components every appear. The
/// upstream call is pure and offline (it just builds a deep link), so a
/// long TTL is fine — the cache exists to keep view appears allocation-free.
public final class CachedTravelAdvisoryService: TravelAdvisoryService, @unchecked Sendable {

    public static let defaultTTL: TimeInterval = 24 * 60 * 60

    private struct Entry {
        let link: TravelAdvisoryLink
        let storedAt: Date
    }

    private let upstream: any TravelAdvisoryService
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private let lock = NSLock()
    private var cache: [String: Entry] = [:]

    public init(
        upstream: any TravelAdvisoryService,
        ttl: TimeInterval = CachedTravelAdvisoryService.defaultTTL,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.upstream = upstream
        self.ttl = ttl
        self.now = now
    }

    public func advisory(forDestination name: String) -> TravelAdvisoryLink {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let timestamp = now()
        if let hit = lookup(key: key, at: timestamp) { return hit }
        let link = upstream.advisory(forDestination: name)
        store(link, key: key, at: timestamp)
        return link
    }

    private func lookup(key: String, at instant: Date) -> TravelAdvisoryLink? {
        lock.lock(); defer { lock.unlock() }
        guard let entry = cache[key] else { return nil }
        if instant.timeIntervalSince(entry.storedAt) > ttl { return nil }
        return entry.link
    }

    private func store(_ link: TravelAdvisoryLink, key: String, at instant: Date) {
        lock.lock(); defer { lock.unlock() }
        cache[key] = Entry(link: link, storedAt: instant)
    }
}
