@testable import PersonalHygiene
@preconcurrency import XCTest

@MainActor
final class TripEmergencyContactsTelURLTests: XCTestCase {

    func test_telURL_stripsFormatting() {
        let url = TripEmergencyContactsSection.telURL(from: "+34 600 11 22 33")
        XCTAssertEqual(url?.absoluteString, "tel:+34600112233")
    }

    func test_telURL_returnsNilForEmpty() {
        XCTAssertNil(TripEmergencyContactsSection.telURL(from: ""))
        XCTAssertNil(TripEmergencyContactsSection.telURL(from: "   "))
    }

    func test_telURL_keepsOnlyFirstPlus() {
        let url = TripEmergencyContactsSection.telURL(from: "+1 (415) 555-0123")
        XCTAssertEqual(url?.absoluteString, "tel:+14155550123")
    }
}
