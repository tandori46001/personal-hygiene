import XCTest

@testable import PersonalHygiene

final class CachedCurrencyServiceTests: XCTestCase {

    private actor StubCurrency: CurrencyService {
        var calls: Int = 0
        var rate: Double

        init(rate: Double) { self.rate = rate }

        func convert(amount: Double, from: String, to: String) async throws -> CurrencyConversion {
            calls += 1
            return CurrencyConversion(
                from: from.uppercased(),
                to: to.uppercased(),
                rate: rate,
                amountConverted: rate * amount
            )
        }

        func setRate(_ value: Double) { rate = value }
        func callCount() -> Int { calls }
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

    func test_secondCall_within_ttl_servedFromCache_amountAppliedLocally() async throws {
        let stub = StubCurrency(rate: 1.1)
        let clock = Clock(Date(timeIntervalSince1970: 1_000_000))
        let service = CachedCurrencyService(upstream: stub, ttl: 60) { clock.now }

        let first = try await service.convert(amount: 100, from: "EUR", to: "USD")
        XCTAssertEqual(first.amountConverted, 110, accuracy: 0.0001)

        // Different amount on a cache hit should still apply locally without
        // hitting upstream a second time.
        let second = try await service.convert(amount: 50, from: "EUR", to: "USD")
        XCTAssertEqual(second.amountConverted, 55, accuracy: 0.0001)

        let calls = await stub.callCount()
        XCTAssertEqual(calls, 1)
    }

    func test_callAfterTTL_refetches() async throws {
        let stub = StubCurrency(rate: 1.1)
        let clock = Clock(Date(timeIntervalSince1970: 1_000_000))
        let service = CachedCurrencyService(upstream: stub, ttl: 60) { clock.now }

        _ = try await service.convert(amount: 100, from: "EUR", to: "USD")
        clock.advance(by: 120)
        await stub.setRate(1.2)
        let refreshed = try await service.convert(amount: 100, from: "EUR", to: "USD")

        XCTAssertEqual(refreshed.rate, 1.2, accuracy: 0.0001)
        let calls = await stub.callCount()
        XCTAssertEqual(calls, 2)
    }

    func test_cacheKey_isCaseInsensitive() {
        XCTAssertEqual(
            CachedCurrencyService.cacheKey(from: "eur", to: "usd"),
            CachedCurrencyService.cacheKey(from: "EUR", to: "USD")
        )
    }

    func test_differentPair_isSeparateEntry() async throws {
        let stub = StubCurrency(rate: 1.1)
        let service = CachedCurrencyService(upstream: stub, ttl: 60)
        _ = try await service.convert(amount: 100, from: "EUR", to: "USD")
        _ = try await service.convert(amount: 100, from: "EUR", to: "GBP")
        let calls = await stub.callCount()
        XCTAssertEqual(calls, 2)
    }
}
