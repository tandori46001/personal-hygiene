@testable import PersonalHygiene
import XCTest

final class WeatherForecastCacheCountersTests: XCTestCase {

    override func setUp() {
        super.setUp()
        WeatherForecastCacheCounters.shared.reset()
    }

    override func tearDown() {
        WeatherForecastCacheCounters.shared.reset()
        super.tearDown()
    }

    func test_initialSnapshotIsZero() {
        let snapshot = WeatherForecastCacheCounters.shared.snapshot
        XCTAssertEqual(snapshot.hits, 0)
        XCTAssertEqual(snapshot.misses, 0)
    }

    func test_recordIncrementsCounters() {
        WeatherForecastCacheCounters.shared.recordHit()
        WeatherForecastCacheCounters.shared.recordHit()
        WeatherForecastCacheCounters.shared.recordMiss()
        let snapshot = WeatherForecastCacheCounters.shared.snapshot
        XCTAssertEqual(snapshot.hits, 2)
        XCTAssertEqual(snapshot.misses, 1)
    }

    func test_resetClearsCounters() {
        WeatherForecastCacheCounters.shared.recordHit()
        WeatherForecastCacheCounters.shared.reset()
        let snapshot = WeatherForecastCacheCounters.shared.snapshot
        XCTAssertEqual(snapshot.hits, 0)
        XCTAssertEqual(snapshot.misses, 0)
    }
}
