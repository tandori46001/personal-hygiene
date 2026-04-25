import XCTest
@testable import PersonalHygiene

final class BlockTests: XCTestCase {

    func test_endMinutesFromMidnight_isStartPlusDuration() {
        let block = Block(
            title: "Test",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        XCTAssertEqual(block.endMinutesFromMidnight, 7 * 60 + 30)
    }

    func test_initWithDefaults_setsExpectedFields() {
        let block = Block(
            title: "Test",
            category: .meal,
            startMinutesFromMidnight: 0,
            durationMinutes: 30
        )
        XCTAssertEqual(block.notificationLeadMinutes, 15)
        XCTAssertFalse(block.isDeepFocus)
        XCTAssertNil(block.notes)
    }

    func test_codable_roundtrip_preservesAllFields() throws {
        let original = Block(
            title: "Medicación",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            notes: "Con agua",
            notificationLeadMinutes: 5,
            isDeepFocus: false
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Block.self, from: encoded)
        XCTAssertEqual(original, decoded)
    }
}
