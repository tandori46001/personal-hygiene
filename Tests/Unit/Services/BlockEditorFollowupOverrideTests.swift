@testable import PersonalHygiene
import XCTest

/// Round-25 slice T1.4: per-block override beats template default — when
/// `PerBlockFollowUpOverrideStore.minutes(...)` is set, the resolved
/// follow-up offset must be the override, not the global default.
final class BlockEditorFollowupOverrideTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.followup-resolution-\(UUID().uuidString)")!
    }

    func test_resolvedOffset_prefersOverrideOverDefault() {
        let blockID = UUID()
        PerBlockFollowUpOverrideStore.set(45, for: blockID, in: defaults)
        let override = PerBlockFollowUpOverrideStore.minutes(for: blockID, defaults: defaults)
        XCTAssertEqual(override, 45)
        XCTAssertNotEqual(override, MedicationFollowUpDelayStore.defaultMinutes)
    }

    func test_resolvedOffset_fallsBackToDefaultWhenNoOverride() {
        let blockID = UUID()
        let override = PerBlockFollowUpOverrideStore.minutes(for: blockID, defaults: defaults)
        XCTAssertNil(override)
        let resolved = override ?? MedicationFollowUpDelayStore.defaultMinutes
        XCTAssertEqual(resolved, MedicationFollowUpDelayStore.defaultMinutes)
    }

    func test_overrides_areBlockSpecific() {
        let blockA = UUID()
        let blockB = UUID()
        PerBlockFollowUpOverrideStore.set(15, for: blockA, in: defaults)
        PerBlockFollowUpOverrideStore.set(60, for: blockB, in: defaults)
        XCTAssertEqual(PerBlockFollowUpOverrideStore.minutes(for: blockA, defaults: defaults), 15)
        XCTAssertEqual(PerBlockFollowUpOverrideStore.minutes(for: blockB, defaults: defaults), 60)
    }
}
