import XCTest

@testable import PersonalHygiene

final class CachedTravelAdvisoryServiceTests: XCTestCase {

    private final class CountingAdvisory: TravelAdvisoryService, @unchecked Sendable {
        var calls = 0
        func advisory(forDestination name: String) -> TravelAdvisoryLink {
            calls += 1
            return TravelAdvisoryLink(
                displayName: name,
                url: URL(string: "https://example.test/\(name)")!,
                source: "test"
            )
        }
    }

    func test_secondLookup_servedFromCache() {
        let counter = CountingAdvisory()
        let service = CachedTravelAdvisoryService(upstream: counter, ttl: 600)

        _ = service.advisory(forDestination: "Mallorca")
        _ = service.advisory(forDestination: "Mallorca")
        _ = service.advisory(forDestination: "  mallorca  ")  // case + trim still hits cache.

        XCTAssertEqual(counter.calls, 1)
    }

    func test_differentDestination_isSeparateEntry() {
        let counter = CountingAdvisory()
        let service = CachedTravelAdvisoryService(upstream: counter)

        _ = service.advisory(forDestination: "Tokyo")
        _ = service.advisory(forDestination: "Lisboa")

        XCTAssertEqual(counter.calls, 2)
    }

    private final class Clock: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Date
        init(_ start: Date) { stored = start }
        var now: Date { lock.lock(); defer { lock.unlock() }; return stored }
        func advance(by seconds: TimeInterval) {
            lock.lock(); defer { lock.unlock() }
            stored = stored.addingTimeInterval(seconds)
        }
    }

    func test_callAfterTTL_refetches() {
        let counter = CountingAdvisory()
        let clock = Clock(Date(timeIntervalSince1970: 0))
        let service = CachedTravelAdvisoryService(upstream: counter, ttl: 60) { clock.now }

        _ = service.advisory(forDestination: "Tokyo")
        clock.advance(by: 120)
        _ = service.advisory(forDestination: "Tokyo")

        XCTAssertEqual(counter.calls, 2)
    }
}
