@preconcurrency import XCTest

@testable import PersonalHygiene

final class HomeLocationStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "HomeLocationStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_location_nilWhenIsSetFalse() {
        let store = HomeLocationStore(defaults: defaults)
        XCTAssertNil(store.location)
    }

    func test_location_returnsStoredCoordinates() {
        defaults.set(true, forKey: HomeLocationStore.isSetKey)
        defaults.set(40.4168, forKey: HomeLocationStore.latitudeKey)
        defaults.set(-3.7038, forKey: HomeLocationStore.longitudeKey)
        defaults.set("Casa", forKey: HomeLocationStore.nameKey)

        let store = HomeLocationStore(defaults: defaults)
        XCTAssertEqual(store.location?.latitude, 40.4168)
        XCTAssertEqual(store.location?.longitude, -3.7038)
        XCTAssertEqual(store.location?.displayName, "Casa")
    }

    func test_location_dropsBlankName() {
        defaults.set(true, forKey: HomeLocationStore.isSetKey)
        defaults.set(40.4168, forKey: HomeLocationStore.latitudeKey)
        defaults.set(-3.7038, forKey: HomeLocationStore.longitudeKey)
        defaults.set("", forKey: HomeLocationStore.nameKey)

        let store = HomeLocationStore(defaults: defaults)
        XCTAssertNil(store.location?.displayName)
    }

    func test_location_nilWhenStoredCoordinatesAreInvalid() {
        defaults.set(true, forKey: HomeLocationStore.isSetKey)
        defaults.set(200.0, forKey: HomeLocationStore.latitudeKey)
        defaults.set(-500.0, forKey: HomeLocationStore.longitudeKey)

        let store = HomeLocationStore(defaults: defaults)
        XCTAssertNil(store.location)
    }
}
