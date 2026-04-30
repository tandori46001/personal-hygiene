@testable import PersonalHygiene
@preconcurrency import XCTest

final class PerBlockFollowUpOverrideStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.followup-override-\(UUID().uuidString)")!
    }

    func test_minutes_nilWhenUnset() {
        XCTAssertNil(PerBlockFollowUpOverrideStore.minutes(for: UUID(), defaults: defaults))
    }

    func test_set_andRead() {
        let id = UUID()
        PerBlockFollowUpOverrideStore.set(45, for: id, in: defaults)
        XCTAssertEqual(PerBlockFollowUpOverrideStore.minutes(for: id, defaults: defaults), 45)
    }

    func test_set_invalidValueIgnored() {
        let id = UUID()
        PerBlockFollowUpOverrideStore.set(7, for: id, in: defaults)
        XCTAssertNil(PerBlockFollowUpOverrideStore.minutes(for: id, defaults: defaults))
    }

    func test_clearByNil() {
        let id = UUID()
        PerBlockFollowUpOverrideStore.set(30, for: id, in: defaults)
        PerBlockFollowUpOverrideStore.set(nil, for: id, in: defaults)
        XCTAssertNil(PerBlockFollowUpOverrideStore.minutes(for: id, defaults: defaults))
    }
}
