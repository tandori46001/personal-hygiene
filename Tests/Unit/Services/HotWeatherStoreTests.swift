@testable import PersonalHygiene
import XCTest

final class HotWeatherStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.hot-weather-\(UUID().uuidString)")!
    }

    func test_disabled_returnsBaseGoal() {
        XCTAssertFalse(HotWeatherStore.isEnabled(defaults: defaults))
        XCTAssertEqual(HotWeatherStore.adjusted(base: 2_000, defaults: defaults), 2_000)
    }

    func test_enabled_addsBump() {
        HotWeatherStore.setEnabled(true, in: defaults)
        XCTAssertEqual(HotWeatherStore.adjusted(base: 2_000, defaults: defaults), 2_500)
    }

    func test_customBump() {
        HotWeatherStore.setEnabled(true, in: defaults)
        HotWeatherStore.setBumpMilliliters(750, in: defaults)
        XCTAssertEqual(HotWeatherStore.bumpMilliliters(defaults: defaults), 750)
        XCTAssertEqual(HotWeatherStore.adjusted(base: 2_000, defaults: defaults), 2_750)
    }

    func test_zeroBump_fallsBackToDefault() {
        HotWeatherStore.setBumpMilliliters(0, in: defaults)
        XCTAssertEqual(
            HotWeatherStore.bumpMilliliters(defaults: defaults),
            HotWeatherStore.defaultBumpMilliliters
        )
    }
}
