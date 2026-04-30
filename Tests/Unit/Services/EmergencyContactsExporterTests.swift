@testable import PersonalHygiene
@preconcurrency import XCTest

final class EmergencyContactsExporterTests: XCTestCase {

    func test_vCard_singleContactStructure() {
        let contact = TripEmergencyContact(
            label: "Mom",
            phone: "+34 600 000 000",
            notes: "Family"
        )
        let card = EmergencyContactsExporter.vCard(for: contact)
        XCTAssertTrue(card.hasPrefix("BEGIN:VCARD"))
        XCTAssertTrue(card.hasSuffix("END:VCARD"))
        XCTAssertTrue(card.contains("FN:Mom"))
        XCTAssertTrue(card.contains("+34 600 000 000"))
        XCTAssertTrue(card.contains("NOTE:Family"))
    }

    func test_vCard_omitsEmptyOptionalFields() {
        let contact = TripEmergencyContact(label: "X", phone: "")
        let card = EmergencyContactsExporter.vCard(for: contact)
        XCTAssertFalse(card.contains("TEL"))
        XCTAssertFalse(card.contains("NOTE"))
    }

    func test_vCard_escapesCommaAndSemicolon() {
        let contact = TripEmergencyContact(
            label: "Name, Smith; PhD",
            phone: "+1 555"
        )
        let card = EmergencyContactsExporter.vCard(for: contact)
        XCTAssertTrue(card.contains("\\,"))
        XCTAssertTrue(card.contains("\\;"))
    }

    func test_vCardArray_joinsMultipleEntries() {
        let contacts = [
            TripEmergencyContact(label: "A", phone: "1"),
            TripEmergencyContact(label: "B", phone: "2"),
        ]
        let combined = EmergencyContactsExporter.vCard(for: contacts)
        let beginCount = combined.components(separatedBy: "BEGIN:VCARD").count - 1
        XCTAssertEqual(beginCount, 2)
    }
}
