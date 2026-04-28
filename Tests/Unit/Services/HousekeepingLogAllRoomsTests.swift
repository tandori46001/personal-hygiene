@testable import PersonalHygiene
import XCTest

final class HousekeepingLogAllRoomsTests: XCTestCase {

    private let suite = "housekeepingAllRoomsTests-\(UUID().uuidString)"
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

    func test_allRooms_emptyForFreshStore() {
        XCTAssertTrue(HousekeepingCompletionLog.allRooms(in: defaults).isEmpty)
    }

    func test_allRooms_returnsSortedRoomNames() {
        HousekeepingCompletionLog.record(room: "kitchen", on: Date(), in: defaults)
        HousekeepingCompletionLog.record(room: "bath", on: Date(), in: defaults)
        HousekeepingCompletionLog.record(room: "attic", on: Date(), in: defaults)
        let rooms = HousekeepingCompletionLog.allRooms(in: defaults)
        XCTAssertEqual(rooms, ["attic", "bath", "kitchen"])
    }
}
