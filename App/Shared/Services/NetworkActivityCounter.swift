import Foundation

/// Round-13 slice 21: process-local count of outgoing API calls broken down
/// by upstream service. Cache hits do NOT increment — only real network
/// round-trips. Resets at relaunch (intentionally — short-window debug
/// signal, not analytics).
public final class NetworkActivityCounter: @unchecked Sendable {

    public enum Source: String, Sendable, Hashable, CaseIterable {
        case frankfurter
        case openMeteo
        case advisory
        case other
    }

    public static let shared = NetworkActivityCounter()

    private let lock = NSLock()
    private var counts: [Source: Int] = [:]
    private var lastFiredAt: [Source: Date] = [:]

    public func record(_ source: Source, at date: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        counts[source, default: 0] += 1
        lastFiredAt[source] = date
    }

    public func count(for source: Source) -> Int {
        lock.lock(); defer { lock.unlock() }
        return counts[source, default: 0]
    }

    public func lastFired(for source: Source) -> Date? {
        lock.lock(); defer { lock.unlock() }
        return lastFiredAt[source]
    }

    public var totals: [Source: Int] {
        lock.lock(); defer { lock.unlock() }
        return counts
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        counts = [:]
        lastFiredAt = [:]
    }
}
