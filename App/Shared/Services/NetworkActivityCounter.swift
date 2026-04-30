import Foundation

/// Round-13 slice 21: process-local count of outgoing API calls broken down
/// by upstream service. Cache hits do NOT increment — only real network
/// round-trips. Resets at relaunch (intentionally — short-window debug
/// signal, not analytics).
///
/// Round-31 (O02/O03): added `Outcome` tracking for rate-limit + 5xx
/// surveillance per ALL OK? §D flag "Open-Meteo + Frankfurter rate-limit
/// silence". `record(_:)` still counts attempts (called before the
/// request); the new `recordOutcome(_:outcome:)` is called after the
/// response and partitions results into success/rateLimited/serverError/
/// networkError/decodingError. The Diagnostics surface shows the
/// breakdown when any non-success outcome has occurred.
public final class NetworkActivityCounter: @unchecked Sendable {

    public enum Source: String, Sendable, Hashable, CaseIterable {
        case frankfurter
        case openMeteo
        case advisory
        case other
    }

    public enum Outcome: String, Sendable, Hashable, CaseIterable {
        case success
        case rateLimited
        case serverError
        case networkError
        case decodingError
    }

    public static let shared = NetworkActivityCounter()

    private let lock = NSLock()
    private var counts: [Source: Int] = [:]
    private var lastFiredAt: [Source: Date] = [:]
    private var outcomeCounts: [Source: [Outcome: Int]] = [:]
    private var lastOutcomeAt: [Source: [Outcome: Date]] = [:]

    public func record(_ source: Source, at date: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        counts[source, default: 0] += 1
        lastFiredAt[source] = date
    }

    public func recordOutcome(_ source: Source, outcome: Outcome, at date: Date = Date()) {
        lock.lock(); defer { lock.unlock() }
        var perSource = outcomeCounts[source, default: [:]]
        perSource[outcome, default: 0] += 1
        outcomeCounts[source] = perSource
        var perDate = lastOutcomeAt[source, default: [:]]
        perDate[outcome] = date
        lastOutcomeAt[source] = perDate
    }

    public func count(for source: Source) -> Int {
        lock.lock(); defer { lock.unlock() }
        return counts[source, default: 0]
    }

    public func count(for source: Source, outcome: Outcome) -> Int {
        lock.lock(); defer { lock.unlock() }
        return outcomeCounts[source]?[outcome, default: 0] ?? 0
    }

    public func outcomes(for source: Source) -> [Outcome: Int] {
        lock.lock(); defer { lock.unlock() }
        return outcomeCounts[source, default: [:]]
    }

    public func lastFired(for source: Source) -> Date? {
        lock.lock(); defer { lock.unlock() }
        return lastFiredAt[source]
    }

    public func lastOutcome(for source: Source, outcome: Outcome) -> Date? {
        lock.lock(); defer { lock.unlock() }
        return lastOutcomeAt[source]?[outcome]
    }

    public var totals: [Source: Int] {
        lock.lock(); defer { lock.unlock() }
        return counts
    }

    public var outcomeTotals: [Source: [Outcome: Int]] {
        lock.lock(); defer { lock.unlock() }
        return outcomeCounts
    }

    /// True if any non-success outcome has been recorded for this source.
    /// The Diagnostics surface uses this to decide whether to show the
    /// outcome breakdown row (zero noise when everything is healthy).
    public func hasFailureOutcome(for source: Source) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let perSource = outcomeCounts[source] else { return false }
        for (outcome, count) in perSource where outcome != .success && count > 0 {
            return true
        }
        return false
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        counts = [:]
        lastFiredAt = [:]
        outcomeCounts = [:]
        lastOutcomeAt = [:]
    }
}
