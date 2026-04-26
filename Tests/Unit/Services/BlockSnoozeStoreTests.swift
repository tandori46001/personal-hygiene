import XCTest

@testable import PersonalHygiene

final class BlockSnoozeStoreTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        DateComponents(calendar: gregorianUTC(), year: year, month: month, day: day).date!
    }

    func test_inMemory_marksAndReadsForSameDay() {
        let store = InMemoryBlockSnoozeStore()
        let blockID = UUID()
        let today = date(2026, 4, 26)
        XCTAssertFalse(store.isSnoozed(blockID: blockID, on: today, calendar: gregorianUTC()))

        let dayKey = "2026-04-26"
        store.markSnoozed(blockID: blockID, dayKey: dayKey)
        XCTAssertTrue(store.isSnoozed(blockID: blockID, on: today, calendar: gregorianUTC()))
    }

    func test_inMemory_doesNotLeakAcrossDays() {
        let store = InMemoryBlockSnoozeStore()
        let blockID = UUID()
        store.markSnoozed(blockID: blockID, dayKey: "2026-04-26")

        let nextDay = date(2026, 4, 27)
        XCTAssertFalse(store.isSnoozed(blockID: blockID, on: nextDay, calendar: gregorianUTC()))
    }

    func test_inMemory_doesNotLeakAcrossBlocks() {
        let store = InMemoryBlockSnoozeStore()
        let blockA = UUID()
        let blockB = UUID()
        store.markSnoozed(blockID: blockA, dayKey: "2026-04-26")

        let today = date(2026, 4, 26)
        XCTAssertTrue(store.isSnoozed(blockID: blockA, on: today, calendar: gregorianUTC()))
        XCTAssertFalse(store.isSnoozed(blockID: blockB, on: today, calendar: gregorianUTC()))
    }

    func test_userDefaults_persistsAcrossInstances() {
        let suite = UserDefaults(suiteName: "snooze-\(UUID().uuidString)")!
        suite.removeObject(forKey: UserDefaultsBlockSnoozeStore.storageKey)

        let blockID = UUID()
        let today = date(2026, 4, 26)
        let dayKey = "2026-04-26"

        UserDefaultsBlockSnoozeStore(defaults: suite)
            .markSnoozed(blockID: blockID, dayKey: dayKey)

        let secondInstance = UserDefaultsBlockSnoozeStore(defaults: suite)
        XCTAssertTrue(secondInstance.isSnoozed(blockID: blockID, on: today, calendar: gregorianUTC()))
    }

    // MARK: - Identifier parser

    func test_parser_extractsBlockIDAndDayKey() {
        let blockID = UUID()
        let identifier = "\(NotificationFactory.identifierPrefix)\(blockID.uuidString).2026-04-26"
        let parsed = BlockNotificationIdentifier.parse(identifier)
        XCTAssertEqual(parsed?.blockID, blockID)
        XCTAssertEqual(parsed?.dayKey, "2026-04-26")
    }

    func test_parser_returnsNilForUnrelatedIdentifier() {
        XCTAssertNil(BlockNotificationIdentifier.parse("personal-hygiene.hydration.123"))
        XCTAssertNil(BlockNotificationIdentifier.parse("garbage"))
    }

    func test_parser_returnsNilForMalformedUUID() {
        let identifier = "\(NotificationFactory.identifierPrefix)not-a-uuid.2026-04-26"
        XCTAssertNil(BlockNotificationIdentifier.parse(identifier))
    }
}
