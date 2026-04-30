@preconcurrency import XCTest

@testable import PersonalHygiene

final class CachedTravelAdvisoryListTests: XCTestCase {

    /// Counts upstream invocations to prove the cache layer is doing its job.
    private final class CountingAdvisoryService: TravelAdvisoryService, @unchecked Sendable {
        var singleCount = 0
        var listCount = 0

        func advisory(forDestination name: String) -> TravelAdvisoryLink {
            singleCount += 1
            return TravelAdvisoryLink(displayName: name, url: URL(string: "https://example.test")!, source: "test")
        }

        func advisories(forDestination name: String) -> [TravelAdvisoryLink] {
            listCount += 1
            return [advisory(forDestination: name), advisory(forDestination: name + "-alt")]
        }
    }

    func test_advisories_cachesPerDestination() {
        let upstream = CountingAdvisoryService()
        let cached = CachedTravelAdvisoryService(
            upstream: upstream,
            ttl: 60,
            now: { Date(timeIntervalSince1970: 1000) }
        )
        upstream.singleCount = 0
        upstream.listCount = 0

        _ = cached.advisories(forDestination: "Spain")
        _ = cached.advisories(forDestination: "Spain")
        _ = cached.advisories(forDestination: "spain  ")  // same after normalize

        XCTAssertEqual(upstream.listCount, 1, "second call should be a cache hit")
    }

    /// `Sendable`-conformant clock so the closure passed to
    /// `CachedTravelAdvisoryService.now` doesn't capture a non-Sendable mutable
    /// var. Lock-protected so writes from the test body are visible inside
    /// the closure.
    private final class TestClock: @unchecked Sendable {
        private var date: Date
        private let lock = NSLock()
        init(_ start: Date) { self.date = start }
        func read() -> Date { lock.lock(); defer { lock.unlock() }; return date }
        func advance(to: Date) { lock.lock(); defer { lock.unlock() }; date = to }
    }

    func test_advisories_ttlExpiryReinvokesUpstream() {
        let upstream = CountingAdvisoryService()
        let clock = TestClock(Date(timeIntervalSince1970: 0))
        let cached = CachedTravelAdvisoryService(
            upstream: upstream,
            ttl: 60,
            now: { clock.read() }
        )

        _ = cached.advisories(forDestination: "Italy")
        clock.advance(to: Date(timeIntervalSince1970: 120))  // past TTL
        _ = cached.advisories(forDestination: "Italy")

        XCTAssertEqual(upstream.listCount, 2)
    }

    func test_advisories_differentDestinationsAreSeparateEntries() {
        let upstream = CountingAdvisoryService()
        let cached = CachedTravelAdvisoryService(upstream: upstream, ttl: 60, now: { Date() })

        _ = cached.advisories(forDestination: "France")
        _ = cached.advisories(forDestination: "Japan")

        XCTAssertEqual(upstream.listCount, 2)
    }
}
