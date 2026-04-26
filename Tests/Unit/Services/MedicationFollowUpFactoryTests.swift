import XCTest

@testable import PersonalHygiene

final class MedicationFollowUpFactoryTests: XCTestCase {

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

    private func medicationBlock() -> Block {
        Block(
            title: "Pastilla",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-A"
        )
    }

    func test_notification_nilForBlockWithoutMedicationConcept() {
        let block = Block(title: "Aseo", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        let result = MedicationFollowUpFactory.notification(
            for: block,
            primaryTrigger: date(year: 2026, month: 4, day: 25),
            title: "x",
            body: nil,
            dayKey: "2026-04-25"
        )
        XCTAssertNil(result)
    }

    func test_notification_offsetsTriggerByDefault30Minutes() {
        let block = medicationBlock()
        let primary = date(year: 2026, month: 4, day: 25, hour: 8)
        let notif = MedicationFollowUpFactory.notification(
            for: block,
            primaryTrigger: primary,
            title: "Pastilla",
            body: "Hora de la pastilla",
            dayKey: "2026-04-25"
        )
        XCTAssertNotNil(notif)
        XCTAssertEqual(notif?.triggerDate, primary.addingTimeInterval(30 * 60))
        XCTAssertEqual(notif?.isCritical, true)
        XCTAssertEqual(notif?.threadIdentifier, NotificationThreadID.medication)
        XCTAssertEqual(notif?.categoryIdentifier, NotificationCategoryID.medication)
    }

    func test_notification_offsetIsCustomizable() {
        let block = medicationBlock()
        let primary = date(year: 2026, month: 4, day: 25, hour: 8)
        let notif = MedicationFollowUpFactory.notification(
            for: block,
            primaryTrigger: primary,
            offsetMinutes: 15,
            title: "Pastilla",
            body: nil,
            dayKey: "2026-04-25"
        )
        XCTAssertEqual(notif?.triggerDate, primary.addingTimeInterval(15 * 60))
    }

    func test_notification_identifierIncludesBlockIDAndDayKey() {
        let block = medicationBlock()
        let notif = MedicationFollowUpFactory.notification(
            for: block,
            primaryTrigger: date(year: 2026, month: 4, day: 25, hour: 8),
            title: "Pastilla",
            body: nil,
            dayKey: "2026-04-25"
        )
        XCTAssertTrue(notif?.identifier.hasPrefix(MedicationFollowUpFactory.identifierPrefix) ?? false)
        XCTAssertTrue(notif?.identifier.contains(block.id.uuidString) ?? false)
        XCTAssertTrue(notif?.identifier.hasSuffix(".2026-04-25") ?? false)
    }

    func test_followUp_reusesPrimaryTitleAndAppendsBodySuffix() {
        let block = medicationBlock()
        let primary = ScheduledNotification(
            identifier: "personal-hygiene.block.\(block.id).2026-04-25",
            title: "Pastilla",
            body: "Hora de tu pastilla",
            triggerDate: date(year: 2026, month: 4, day: 25, hour: 8),
            isCritical: true
        )
        let followUp = MedicationFollowUpFactory.followUp(
            for: primary,
            block: block,
            dayKey: "2026-04-25"
        )
        XCTAssertEqual(followUp?.title, "Pastilla")
        XCTAssertTrue(followUp?.body?.contains("Hora de tu pastilla") ?? false)
        XCTAssertEqual(
            followUp?.triggerDate,
            primary.triggerDate.addingTimeInterval(30 * 60)
        )
    }

    func test_followUp_nilForNonMedicationBlock() {
        let block = Block(title: "Aseo", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        let primary = ScheduledNotification(
            identifier: "x",
            title: "Aseo",
            body: nil,
            triggerDate: Date(),
            isCritical: false
        )
        XCTAssertNil(MedicationFollowUpFactory.followUp(for: primary, block: block, dayKey: "2026-04-25"))
    }
}
