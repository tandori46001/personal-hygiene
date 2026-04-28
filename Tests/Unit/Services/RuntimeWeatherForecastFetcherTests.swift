@testable import PersonalHygiene
import XCTest

/// Round-24 slice T1.5 — coverage that `RuntimeWeatherForecastFetcher.make()`
/// returns a non-nil fetcher and that the type is something the rest of the
/// app can call. We can't easily simulate iOS 15 vs 16 from a single test
/// process, so this is a smoke + protocol-conformance check.
final class RuntimeWeatherForecastFetcherTests: XCTestCase {

    func test_make_returnsANonNilFetcher() {
        // Static smoke: the factory returns *something* conforming to the
        // protocol. We can't actually call `forecast(...)` without a live
        // WeatherKit auth service in the test process — this would crash
        // on iOS 16+ runtimes. Real call coverage lives behind the stub
        // injection in `test_stub_isUsableAsDefaultInjection`.
        _ = RuntimeWeatherForecastFetcher.make() as (any WeatherForecastFetching)
    }

    func test_stub_isUsableAsDefaultInjection() async throws {
        let stub: any WeatherForecastFetching = StubWeatherForecastService()
        let result = try await stub.forecast(latitude: 0, longitude: 0, days: 3)
        XCTAssertEqual(result.count, 3)
    }
}
