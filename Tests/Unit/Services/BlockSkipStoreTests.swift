import XCTest

@testable import PersonalHygiene

final class BlockSkipStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "BlockSkipStoreTests-\(UUID().uuidString)")
        defaults.removePersistentDomain(forName: "BlockSkipStoreTests")
    }

    override func tearDown() {
        defaults.removeObject(forKey: UserDefaultsBlockSkipStore.storageKey)
        super.tearDown()
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    func test_isSkipped_defaultsToFalse() {
        let store = UserDefaultsBlockSkipStore(defaults: defaults)
        let id = UUID()
        XCTAssertFalse(store.isSkipped(blockID: id, on: Date(), calendar: calendar))
    }

    func test_skipThenUnskip() {
        let store = UserDefaultsBlockSkipStore(defaults: defaults)
        let id = UUID()
        let date = Date(timeIntervalSince1970: 0)
        store.skip(blockID: id, on: date, calendar: calendar)
        XCTAssertTrue(store.isSkipped(blockID: id, on: date, calendar: calendar))
        store.unskip(blockID: id, on: date, calendar: calendar)
        XCTAssertFalse(store.isSkipped(blockID: id, on: date, calendar: calendar))
    }

    func test_skipIsScopedPerDay() {
        let store = UserDefaultsBlockSkipStore(defaults: defaults)
        let id = UUID()
        let day1 = DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date!
        let day2 = DateComponents(calendar: calendar, year: 2026, month: 4, day: 26).date!

        store.skip(blockID: id, on: day1, calendar: calendar)

        XCTAssertTrue(store.isSkipped(blockID: id, on: day1, calendar: calendar))
        XCTAssertFalse(store.isSkipped(blockID: id, on: day2, calendar: calendar))
    }

    func test_skipIsScopedPerBlock() {
        let store = UserDefaultsBlockSkipStore(defaults: defaults)
        let idA = UUID()
        let idB = UUID()
        let date = Date()
        store.skip(blockID: idA, on: date, calendar: calendar)

        XCTAssertTrue(store.isSkipped(blockID: idA, on: date, calendar: calendar))
        XCTAssertFalse(store.isSkipped(blockID: idB, on: date, calendar: calendar))
    }

    func test_purgeStale_dropsOldEntries() {
        let store = UserDefaultsBlockSkipStore(defaults: defaults)
        let id = UUID()
        let oldDay = DateComponents(calendar: calendar, year: 2025, month: 1, day: 1).date!
        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date!

        store.skip(blockID: id, on: oldDay, calendar: calendar)
        XCTAssertTrue(store.isSkipped(blockID: id, on: oldDay, calendar: calendar))

        store.purgeStale(before: now, calendar: calendar, keepLastDays: 7)

        XCTAssertFalse(store.isSkipped(blockID: id, on: oldDay, calendar: calendar))
    }

    func test_inMemoryStore_basics() {
        let store = InMemoryBlockSkipStore()
        let id = UUID()
        let date = Date()
        XCTAssertFalse(store.isSkipped(blockID: id, on: date, calendar: calendar))
        store.skip(blockID: id, on: date, calendar: calendar)
        XCTAssertTrue(store.isSkipped(blockID: id, on: date, calendar: calendar))
        store.unskip(blockID: id, on: date, calendar: calendar)
        XCTAssertFalse(store.isSkipped(blockID: id, on: date, calendar: calendar))
    }
}
