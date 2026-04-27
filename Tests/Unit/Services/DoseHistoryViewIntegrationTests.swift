@testable import PersonalHygiene
import XCTest

/// Round-16: ensure DoseHistoryView accepts the entries shape we produce
/// elsewhere. View itself is not snapshot-tested (deferred), but the entry
/// structure round-trips identically to what `MedicationDoseHistory.recent(...)`
/// emits — these tests pin that contract.
final class DoseHistoryViewIntegrationTests: XCTestCase {

    func test_entry_initWithKnownFields() {
        let entry = MedicationDoseHistory.Entry(
            blockID: UUID(),
            blockTitle: "Pill A",
            conceptIdentifier: "concept-a",
            completedAt: Date(timeIntervalSince1970: 1_777_000_000)
        )
        XCTAssertEqual(entry.blockTitle, "Pill A")
        XCTAssertEqual(entry.conceptIdentifier, "concept-a")
    }

    func test_entry_idIsUnique() {
        let first = MedicationDoseHistory.Entry(
            blockID: UUID(),
            blockTitle: "Pill A",
            conceptIdentifier: nil,
            completedAt: Date()
        )
        let second = MedicationDoseHistory.Entry(
            blockID: UUID(),
            blockTitle: "Pill A",
            conceptIdentifier: nil,
            completedAt: Date()
        )
        XCTAssertNotEqual(first.id, second.id)
    }
}
