@testable import PersonalHygiene
@preconcurrency import XCTest

final class QuietHoursStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "test.quiet-hours-\(UUID().uuidString)")!
    }

    func test_disabled_byDefault() {
        XCTAssertFalse(QuietHoursStore.isEnabled(defaults: defaults))
    }

    func test_setEnabled_persists() {
        QuietHoursStore.setEnabled(true, in: defaults)
        XCTAssertTrue(QuietHoursStore.isEnabled(defaults: defaults))
    }

    func test_contains_simpleWindow() {
        // 09:00 → 17:00
        XCTAssertTrue(QuietHoursStore.contains(triggerMinutes: 12 * 60, startMinutes: 9 * 60, endMinutes: 17 * 60))
        XCTAssertFalse(QuietHoursStore.contains(triggerMinutes: 8 * 60, startMinutes: 9 * 60, endMinutes: 17 * 60))
        XCTAssertFalse(QuietHoursStore.contains(triggerMinutes: 17 * 60, startMinutes: 9 * 60, endMinutes: 17 * 60))
    }

    func test_contains_wrapAround() {
        // 22:00 → 07:00 next day
        XCTAssertTrue(QuietHoursStore.contains(triggerMinutes: 23 * 60, startMinutes: 22 * 60, endMinutes: 7 * 60))
        XCTAssertTrue(QuietHoursStore.contains(triggerMinutes: 3 * 60, startMinutes: 22 * 60, endMinutes: 7 * 60))
        XCTAssertFalse(QuietHoursStore.contains(triggerMinutes: 12 * 60, startMinutes: 22 * 60, endMinutes: 7 * 60))
    }
}
