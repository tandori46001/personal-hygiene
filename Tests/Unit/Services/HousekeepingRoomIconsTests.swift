@testable import PersonalHygiene
import XCTest

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

    func test_store_clear() {
        HousekeepingRoomIconStore.setIconID("fork.knife", forRoom: "Kitchen", in: defaults)
        HousekeepingRoomIconStore.setIconID(nil, forRoom: "Kitchen", in: defaults)
        XCTAssertNil(HousekeepingRoomIconStore.iconID(forRoom: "Kitchen", defaults: defaults))
    }
}
