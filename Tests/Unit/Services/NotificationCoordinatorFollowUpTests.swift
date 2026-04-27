import XCTest

@testable import PersonalHygiene

/// Integration test for `NotificationCoordinator.medicationFollowUps`. Verifies
/// the round-trip from the routine identifier shape produced by
/// `NotificationFactory` through `BlockNotificationIdentifier.parseAny` and
/// out to `MedicationFollowUpFactory`. Tracer for the round-7 caveat where
/// the coordinator used `String.contains` substring match — if the routine
/// identifier shape ever changes, this test trips.
@MainActor
final class NotificationCoordinatorFollowUpTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 8) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour
        ).date!
    }

    func test_medicationFollowUps_pairsEachMedicationPrimary() {
        let cal = gregorianUTC()
        let now = date(year: 2026, month: 4, day: 25, hour: 0)
        let block1 = Block(
            title: "Statin",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-A"
        )
        let block2 = Block(
            title: "Vitamin",
            category: .medication,
            startMinutesFromMidnight: 12 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-B"
        )

        let primaries = NotificationFactory.notifications(for: [block1, block2], on: now, calendar: cal)
        XCTAssertEqual(primaries.count, 2)

        let followUps = NotificationCoordinator.medicationFollowUps(
            primaries: primaries,
            blocks: [block1, block2],
            now: now,
            calendar: cal
        )

        XCTAssertEqual(followUps.count, 2, "one follow-up per medication primary")
        let prefix = MedicationFollowUpFactory.identifierPrefix
        XCTAssertTrue(followUps.allSatisfy { $0.identifier.hasPrefix(prefix) })
        // Follow-up triggers fire 30 min after the primary.
        for primary in primaries {
            let pair = followUps.first { $0.identifier.contains(primary.identifier.suffix(36)) }
                ?? followUps.first { $0.identifier.contains(primary.identifier.split(separator: ".")[2]) }
            XCTAssertNotNil(pair)
        }
    }

    func test_medicationFollowUps_skipsPrimariesForNonMedicationBlocks() {
        let cal = gregorianUTC()
        let now = date(year: 2026, month: 4, day: 25, hour: 0)
        let med = Block(
            title: "Pill",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-A"
        )
        let hygiene = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )

        let primaries = NotificationFactory.notifications(for: [med, hygiene], on: now, calendar: cal)
        XCTAssertEqual(primaries.count, 2)

        let followUps = NotificationCoordinator.medicationFollowUps(
            primaries: primaries,
            blocks: [med, hygiene],
            now: now,
            calendar: cal
        )

        XCTAssertEqual(followUps.count, 1)
    }

    func test_medicationFollowUps_emptyWhenIdentifierShapeUnknown() {
        let cal = gregorianUTC()
        let now = date(year: 2026, month: 4, day: 25, hour: 0)
        let block = Block(
            title: "Pill",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-A"
        )
        let bogusPrimary = ScheduledNotification(
            identifier: "totally-unrelated-identifier",
            title: "Pill",
            body: nil,
            triggerDate: date(year: 2026, month: 4, day: 25, hour: 8),
            isCritical: true,
            threadIdentifier: NotificationThreadID.medication,
            categoryIdentifier: NotificationCategoryID.medication
        )

        let followUps = NotificationCoordinator.medicationFollowUps(
            primaries: [bogusPrimary],
            blocks: [block],
            now: now,
            calendar: cal
        )

        XCTAssertTrue(followUps.isEmpty)
    }

    // MARK: - shifted(_:byMinutes:dropPastBefore:) (round-9 reschedule helper)

    private func makeNotif(at trigger: Date, identifier: String = "id") -> ScheduledNotification {
        ScheduledNotification(
            identifier: identifier,
            title: "T",
            body: nil,
            triggerDate: trigger,
            isCritical: false,
            threadIdentifier: NotificationThreadID.routine,
            categoryIdentifier: NotificationCategoryID.routineBlock
        )
    }

    func test_shifted_addsOffsetToEachTriggerDate() {
        let now = date(year: 2026, month: 4, day: 26, hour: 6)
        let original = makeNotif(at: date(year: 2026, month: 4, day: 26, hour: 9))

        let shifted = NotificationCoordinator.shifted(
            [original],
            byMinutes: 30,
            dropPastBefore: now
        )

        XCTAssertEqual(shifted.count, 1)
        XCTAssertEqual(
            shifted.first?.triggerDate,
            original.triggerDate.addingTimeInterval(30 * 60)
        )
        XCTAssertEqual(shifted.first?.identifier, "id")
    }

    func test_shifted_dropsTriggersThatLandInThePastAfterShift() {
        let now = date(year: 2026, month: 4, day: 26, hour: 12)
        let earlier = makeNotif(at: date(year: 2026, month: 4, day: 26, hour: 11), identifier: "early")
        let later = makeNotif(at: date(year: 2026, month: 4, day: 26, hour: 14), identifier: "late")

        // -120 min shift moves "early" to 09:00 (before now=12:00) → dropped.
        // "late" moves to 12:00 → equal-to-now → also dropped (strictly > now).
        let shifted = NotificationCoordinator.shifted(
            [earlier, later],
            byMinutes: -120,
            dropPastBefore: now
        )

        XCTAssertTrue(shifted.allSatisfy { $0.triggerDate > now })
        XCTAssertFalse(shifted.contains(where: { $0.identifier == "early" }))
    }

    func test_shifted_zeroMinutesIsIdentityForFutureTriggers() {
        let now = date(year: 2026, month: 4, day: 26, hour: 6)
        let future = makeNotif(at: date(year: 2026, month: 4, day: 26, hour: 18))

        let shifted = NotificationCoordinator.shifted(
            [future],
            byMinutes: 0,
            dropPastBefore: now
        )

        XCTAssertEqual(shifted, [future])
    }
}
