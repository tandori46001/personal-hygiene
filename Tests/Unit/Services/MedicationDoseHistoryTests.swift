@testable import PersonalHygiene
@preconcurrency import XCTest

final class MedicationDoseHistoryTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_777_000_000)

    private func makeBlock(id: UUID = UUID(), title: String, concept: String?) -> Block {
        Block(
            id: id,
            title: title,
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: concept
        )
    }

    private func makeCompletion(blockID: UUID, daysAgo: Int) -> BlockCompletion {
        let completedAt = cal.date(byAdding: .day, value: -daysAgo, to: now)!
        return BlockCompletion(
            blockID: blockID,
            dayStart: cal.startOfDay(for: completedAt),
            completedAt: completedAt
        )
    }

    func test_recent_filtersToMedicationOnly() {
        let medID = UUID()
        let nonMedID = UUID()
        let blocks = [
            makeBlock(id: medID, title: "Pill A", concept: "concept-a"),
            makeBlock(id: nonMedID, title: "Brush teeth", concept: nil),
        ]
        let completions = [
            makeCompletion(blockID: medID, daysAgo: 0),
            makeCompletion(blockID: nonMedID, daysAgo: 0),
        ]
        let entries = MedicationDoseHistory.recent(
            completions: completions,
            blocks: blocks,
            days: 30,
            now: now,
            calendar: cal
        )
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.blockTitle, "Pill A")
    }

    func test_recent_dropsBeyondCutoff() {
        let medID = UUID()
        let blocks = [makeBlock(id: medID, title: "Pill", concept: "c")]
        let completions = [
            makeCompletion(blockID: medID, daysAgo: 35),
            makeCompletion(blockID: medID, daysAgo: 5),
        ]
        let entries = MedicationDoseHistory.recent(
            completions: completions,
            blocks: blocks,
            days: 30,
            now: now,
            calendar: cal
        )
        XCTAssertEqual(entries.count, 1)
    }

    func test_recent_newestFirst() {
        let medID = UUID()
        let blocks = [makeBlock(id: medID, title: "Pill", concept: "c")]
        let completions = [
            makeCompletion(blockID: medID, daysAgo: 10),
            makeCompletion(blockID: medID, daysAgo: 1),
            makeCompletion(blockID: medID, daysAgo: 5),
        ]
        let entries = MedicationDoseHistory.recent(
            completions: completions,
            blocks: blocks,
            days: 30,
            now: now,
            calendar: cal
        )
        XCTAssertEqual(entries.count, 3)
        XCTAssertGreaterThan(entries[0].completedAt, entries[1].completedAt)
        XCTAssertGreaterThan(entries[1].completedAt, entries[2].completedAt)
    }
}
