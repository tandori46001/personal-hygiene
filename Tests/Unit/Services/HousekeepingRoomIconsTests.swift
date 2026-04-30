@testable import PersonalHygiene
@preconcurrency import XCTest

final class HousekeepingRoomIconsTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "test.room-icons-\(UUID().uuidString)")!
    }

    func test_palette_nonEmpty() {
        XCTAssertFalse(HousekeepingRoomIcons.palette.isEmpty)
    }

    func test_choice_lookupHit() {
        let kitchen = HousekeepingRoomIcons.palette.first { $0.id == "fork.knife" }
        XCTAssertNotNil(kitchen)
    }

    func test_choice_lookupMiss() {
        XCTAssertNil(HousekeepingRoomIcons.choice(forID: "not-a-real-symbol"))
    }

    func test_store_setAndRead() {
        HousekeepingRoomIconStore.setIconID("fork.knife", forRoom: "Kitchen", in: defaults)
        XCTAssertEqual(
            HousekeepingRoomIconStore.iconID(forRoom: "Kitchen", defaults: defaults),
            "fork.knife"
        )
    }

    /// Round-17 wire: every IconChoice's displayKey resolves to a non-empty
    /// translation, so the picker rows always render with a usable label.
    func test_palette_displayKeysAreNonEmpty() {
        for choice in HousekeepingRoomIcons.palette {
            XCTAssertFalse(choice.displayKey.isEmpty)
            XCTAssertFalse(choice.id.isEmpty)
        }
    }

    func test_store_clear() {
        HousekeepingRoomIconStore.setIconID("fork.knife", forRoom: "Kitchen", in: defaults)
        HousekeepingRoomIconStore.setIconID(nil, forRoom: "Kitchen", in: defaults)
        XCTAssertNil(HousekeepingRoomIconStore.iconID(forRoom: "Kitchen", defaults: defaults))
    }
}
