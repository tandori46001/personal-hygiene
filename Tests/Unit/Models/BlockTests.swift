import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
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

    func test_persistAndFetch_roundtripsAllFields() throws {
        let container = try AppModelContainer.makeInMemory()
        let context = container.mainContext

        let block = Block(
            title: "Medicación",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            notes: "Con agua",
            notificationLeadMinutes: 5
        )
        context.insert(block)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Block>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Medicación")
        XCTAssertEqual(fetched.first?.category, .medication)
        XCTAssertEqual(fetched.first?.notes, "Con agua")
        XCTAssertEqual(fetched.first?.notificationLeadMinutes, 5)
    }
}
