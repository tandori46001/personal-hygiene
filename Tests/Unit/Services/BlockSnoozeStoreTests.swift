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

    // MARK: - parseAny — exhaustive table (L002 guard)

    func test_parseAny_recognizesRoutine() {
        let blockID = UUID()
        let identifier = "\(NotificationFactory.identifierPrefix)\(blockID.uuidString).2026-04-26"
        let parsed = BlockNotificationIdentifier.parseAny(identifier)
        XCTAssertEqual(parsed, .routine(blockID: blockID, dayKey: "2026-04-26"))
        XCTAssertEqual(parsed?.source, .routine)
    }

    func test_parseAny_recognizesHydration() {
        let identifier = "\(HydrationNotificationFactory.identifierPrefix)2026-04-26.3"
        let parsed = BlockNotificationIdentifier.parseAny(identifier)
        XCTAssertEqual(parsed, .hydration(dayKey: "2026-04-26", index: 3))
        XCTAssertEqual(parsed?.source, .hydration)
    }

    func test_parseAny_recognizesMilestone() {
        let milestoneID = UUID()
        let identifier = "\(TripMilestoneNotificationFactory.identifierPrefix)\(milestoneID.uuidString)"
        let parsed = BlockNotificationIdentifier.parseAny(identifier)
        XCTAssertEqual(parsed, .milestone(milestoneID: milestoneID))
        XCTAssertEqual(parsed?.source, .milestone)
    }

    func test_parseAny_recognizesSnoozeRefireFromAnyKind() {
        let blockID = UUID()
        let original = "\(NotificationFactory.identifierPrefix)\(blockID.uuidString).2026-04-26"
        let snoozed = "\(original).snooze.1700000000"
        XCTAssertEqual(
            BlockNotificationIdentifier.parseAny(snoozed),
            .routine(blockID: blockID, dayKey: "2026-04-26")
        )

        let milestoneID = UUID()
        let milestonePrefix = TripMilestoneNotificationFactory.identifierPrefix
        let milestoneSnoozed = "\(milestonePrefix)\(milestoneID.uuidString).snooze.1700000001"
        XCTAssertEqual(
            BlockNotificationIdentifier.parseAny(milestoneSnoozed),
            .milestone(milestoneID: milestoneID)
        )
    }

    func test_parseAny_returnsNilForGarbage() {
        XCTAssertNil(BlockNotificationIdentifier.parseAny(""))
        XCTAssertNil(BlockNotificationIdentifier.parseAny("garbage"))
        XCTAssertNil(BlockNotificationIdentifier.parseAny("personal-hygiene.unknown.abc"))
    }

    func test_parseAny_returnsNilForMalformedHydrationIndex() {
        let identifier = "\(HydrationNotificationFactory.identifierPrefix)2026-04-26.notANumber"
        XCTAssertNil(BlockNotificationIdentifier.parseAny(identifier))
    }

    func test_parseAny_returnsNilForMalformedMilestoneUUID() {
        let identifier = "\(TripMilestoneNotificationFactory.identifierPrefix)not-a-uuid"
        XCTAssertNil(BlockNotificationIdentifier.parseAny(identifier))
    }

    /// Iterates `BlockSnoozeSource.allCases` and round-trips a synthesized
    /// identifier for each kind; if a new source is added without updating
    /// `parseAny`, this test fails — guarding L002.
    func test_parse_recognizesAllKnownPrefixes() {
        for source in BlockSnoozeSource.allCases {
            let identifier: String
            switch source {
            case .routine:
                identifier = "\(NotificationFactory.identifierPrefix)\(UUID().uuidString).2026-04-26"
            case .hydration:
                identifier = "\(HydrationNotificationFactory.identifierPrefix)2026-04-26.0"
            case .milestone:
                identifier = "\(TripMilestoneNotificationFactory.identifierPrefix)\(UUID().uuidString)"
            }
            let parsed = BlockNotificationIdentifier.parseAny(identifier)
            XCTAssertEqual(parsed?.source, source, "parseAny did not recognize the \(source.rawValue) prefix")
        }
    }

    // MARK: - Cross-module BlockSnoozeStore (slice 13)

    func test_inMemory_isSnoozedScopesPerSource() {
        let store = InMemoryBlockSnoozeStore()
        let dayKey = "2026-04-26"
        let today = date(2026, 4, 26)
        let cal = gregorianUTC()
        store.markSnoozed(source: .hydration, key: "1", dayKey: dayKey)
        XCTAssertTrue(store.isSnoozed(source: .hydration, key: "1", on: today, calendar: cal))
        XCTAssertFalse(store.isSnoozed(source: .milestone, key: "1", on: today, calendar: cal))
        XCTAssertFalse(store.isSnoozed(source: .routine, key: "1", on: today, calendar: cal))
    }

    func test_inMemory_legacyRoutineEntryReadableViaNewAPI() {
        let store = InMemoryBlockSnoozeStore()
        let blockID = UUID()
        let dayKey = "2026-04-26"
        let today = date(2026, 4, 26)
        let cal = gregorianUTC()
        store.markSnoozed(blockID: blockID, dayKey: dayKey)
        XCTAssertTrue(
            store.isSnoozed(source: .routine, key: blockID.uuidString, on: today, calendar: cal)
        )
    }

    func test_inMemory_markSnoozedFromParsedHandlesEachKind() {
        let store = InMemoryBlockSnoozeStore()
        let cal = gregorianUTC()
        let today = date(2026, 4, 26)

        let routineID = UUID()
        store.markSnoozed(parsed: .routine(blockID: routineID, dayKey: "2026-04-26"), on: today, calendar: cal)
        XCTAssertTrue(store.isSnoozed(blockID: routineID, on: today, calendar: cal))

        store.markSnoozed(parsed: .hydration(dayKey: "ignored", index: 7), on: today, calendar: cal)
        XCTAssertTrue(store.isSnoozed(source: .hydration, key: "7", on: today, calendar: cal))

        let milestoneID = UUID()
        store.markSnoozed(parsed: .milestone(milestoneID: milestoneID), on: today, calendar: cal)
        XCTAssertTrue(
            store.isSnoozed(source: .milestone, key: milestoneID.uuidString, on: today, calendar: cal)
        )
    }
}
