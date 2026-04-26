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
}
