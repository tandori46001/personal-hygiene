import XCTest

@testable import PersonalHygiene

final class MedicationFollowUpDelayStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test-followup-\(UUID().uuidString)")!
    }

    override func tearDown() {
        defaults.removeObject(forKey: MedicationFollowUpDelayStore.key)
        defaults = nil
        super.tearDown()
    }

    func test_defaultMinutes_returnedWhenUnset() {
        XCTAssertEqual(
            MedicationFollowUpDelayStore.minutes(defaults: defaults),
            MedicationFollowUpDelayStore.defaultMinutes
        )
    }

    func test_set_persistsAllowedValue() {
        MedicationFollowUpDelayStore.set(45, in: defaults)
        XCTAssertEqual(MedicationFollowUpDelayStore.minutes(defaults: defaults), 45)
    }

    func test_set_ignoresDisallowedValue() {
        MedicationFollowUpDelayStore.set(7, in: defaults)
        XCTAssertEqual(
            MedicationFollowUpDelayStore.minutes(defaults: defaults),
            MedicationFollowUpDelayStore.defaultMinutes
        )
    }

    func test_minutes_falsValueOutsideAllowedFallsBackToDefault() {
        defaults.set(99, forKey: MedicationFollowUpDelayStore.key)
        XCTAssertEqual(
            MedicationFollowUpDelayStore.minutes(defaults: defaults),
            MedicationFollowUpDelayStore.defaultMinutes
        )
    }
}

@MainActor
final class MedicationFollowUpFactoryCancelTests: XCTestCase {

    func test_cancelFollowUps_returnsOnlyMatchingPending() {
        let blockA = UUID()
        let blockB = UUID()
        let dayKey = "2026-04-26"
        let pending = [
            MedicationFollowUpFactory.identifier(blockID: blockA, dayKey: dayKey),
            MedicationFollowUpFactory.identifier(blockID: blockB, dayKey: dayKey),
            "personal-hygiene.routine.\(UUID().uuidString).\(dayKey)",
            "personal-hygiene.unrelated.identifier",
        ]
        let result = MedicationFollowUpFactory.cancelFollowUps(
            for: [(blockID: blockA, dayKey: dayKey)],
            in: pending
        )
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(
            result.first,
            MedicationFollowUpFactory.identifier(blockID: blockA, dayKey: dayKey)
        )
    }

    func test_cancelFollowUps_returnsEmptyWhenNoMatch() {
        let target = UUID()
        let result = MedicationFollowUpFactory.cancelFollowUps(
            for: [(blockID: target, dayKey: "2026-04-26")],
            in: ["personal-hygiene.routine.x.y"]
        )
        XCTAssertTrue(result.isEmpty)
    }
}
