@preconcurrency import XCTest

@testable import PersonalHygiene

final class CachedMarineWeatherServiceTests: XCTestCase {

    private actor StubMarine: MarineWeatherService {
        var calls: Int = 0
        var nextResult: MarineConditions

        init(initial: MarineConditions) { self.nextResult = initial }

        func current(at latitude: Double, longitude: Double) async throws -> MarineConditions {
            calls += 1
            return nextResult
        }

        func setResult(_ value: MarineConditions) { nextResult = value }
        func callCount() -> Int { calls }
    }

    private func makeConditions(temp: Double) -> MarineConditions {
        MarineConditions(
            waveHeightMeters: 1.0,
            waveDirectionDegrees: 90,
            wavePeriodSeconds: 5.0,
            seaSurfaceTemperatureCelsius: temp
        )
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

    func test_secondCall_within_ttl_servedFromCache() async throws {
        let stub = StubMarine(initial: makeConditions(temp: 20))
        let clock = Clock(Date(timeIntervalSince1970: 1_000_000))
        let service = CachedMarineWeatherService(upstream: stub, ttl: 60) { clock.now }

        let first = try await service.current(at: 39.5, longitude: 2.5)
        let second = try await service.current(at: 39.5, longitude: 2.5)

        XCTAssertEqual(first, second)
        let calls = await stub.callCount()
        XCTAssertEqual(calls, 1)

        // Different coordinates should miss cache.
        clock.advance(by: 1)
        _ = try await service.current(at: 0, longitude: 0)
        let calls2 = await stub.callCount()
        XCTAssertEqual(calls2, 2)
    }

    func test_callAfterTTL_refetches() async throws {
        let stub = StubMarine(initial: makeConditions(temp: 20))
        let clock = Clock(Date(timeIntervalSince1970: 1_000_000))
        let service = CachedMarineWeatherService(upstream: stub, ttl: 60) { clock.now }

        _ = try await service.current(at: 1, longitude: 2)
        clock.advance(by: 120)
        await stub.setResult(makeConditions(temp: 25))
        let refreshed = try await service.current(at: 1, longitude: 2)

        XCTAssertEqual(refreshed.seaSurfaceTemperatureCelsius, 25)
        let calls = await stub.callCount()
        XCTAssertEqual(calls, 2)
    }

    func test_cacheKey_roundsToFourDecimals() {
        let key1 = CachedMarineWeatherService.cacheKey(latitude: 39.500001, longitude: 2.500001)
        let key2 = CachedMarineWeatherService.cacheKey(latitude: 39.5000019, longitude: 2.5000019)
        XCTAssertEqual(key1, key2)
    }
}
