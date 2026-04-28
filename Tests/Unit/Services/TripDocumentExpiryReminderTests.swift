@testable import PersonalHygiene
import XCTest

final class TripDocumentExpiryReminderTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFromBase: Int) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    private func doc(title: String, daysFromBase: Int) -> TripDocumentExpiryReminder.Document {
        TripDocumentExpiryReminder.Document(title: title, expiresAt: date(daysFromBase))
    }

    func test_returnsDocsExpiringWithinWindow() {
        let docs = [doc(title: "Passport", daysFromBase: 25),
                    doc(title: "Visa", daysFromBase: 5),
                    doc(title: "Far", daysFromBase: 200)]
        let alerts = TripDocumentExpiryReminder.documentsExpiringWithin(
            leadDays: 30,
            documents: docs,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertEqual(alerts.count, 2)
        XCTAssertEqual(alerts.first?.title, "Visa")  // sorted by date
    }

    func test_excludesAlreadyExpiredDocs() {
        let docs = [doc(title: "Old", daysFromBase: -5)]
        let alerts = TripDocumentExpiryReminder.documentsExpiringWithin(
            leadDays: 30,
            documents: docs,
            now: date(0),
            calendar: calendar()
        )
        XCTAssertTrue(alerts.isEmpty)
    }

    func test_daysUntilExpiry_signedAndZero() {
        XCTAssertEqual(
            TripDocumentExpiryReminder.daysUntilExpiry(
                for: doc(title: "x", daysFromBase: 7),
                now: date(0),
                calendar: calendar()
            ),
            7
        )
        XCTAssertEqual(
            TripDocumentExpiryReminder.daysUntilExpiry(
                for: doc(title: "x", daysFromBase: 0),
                now: date(0),
                calendar: calendar()
            ),
            0
        )
    }
}
