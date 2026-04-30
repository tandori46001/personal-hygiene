@testable import PersonalHygiene
@preconcurrency import XCTest

final class WeatherForecastCacheTests: XCTestCase {

    private let suite = "weatherCacheTests-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func sampleForecast(daysFromNow offset: Int) -> WeatherForecast {
        WeatherForecast(
            day: Date().addingTimeInterval(TimeInterval(offset) * 86_400),
            highCelsius: 22,
            lowCelsius: 16,
            precipitationProbability: 0.2,
            symbolName: "sun.max"
        )
    }

    func test_store_andRetrieveWithinTTL() {
        let cache = WeatherForecastCache(defaults: defaults, ttl: 60)
        let forecasts = [sampleForecast(daysFromNow: 0), sampleForecast(daysFromNow: 1)]
        let now = Date()
        cache.store(forecasts, latitude: 41.39, longitude: 2.16, now: now)
        let retrieved = cache.cached(latitude: 41.39, longitude: 2.16, now: now.addingTimeInterval(30))
        XCTAssertEqual(retrieved?.count, 2)
    }

    func test_expiry_dropsStaleEntries() {
        let cache = WeatherForecastCache(defaults: defaults, ttl: 60)
        let now = Date()
        cache.store([sampleForecast(daysFromNow: 0)], latitude: 0, longitude: 0, now: now)
        let later = now.addingTimeInterval(120)
        XCTAssertNil(cache.cached(latitude: 0, longitude: 0, now: later))
    }

    func test_keys_areCoarseGrainedTo2DecimalPlaces() {
        let cache = WeatherForecastCache(defaults: defaults)
        let key1 = cache.key(latitude: 41.391, longitude: 2.161)
        let key2 = cache.key(latitude: 41.394, longitude: 2.164)
        XCTAssertEqual(key1, key2, "rounding to 2 dp keeps the cache compact across nearby coords")
    }
}
