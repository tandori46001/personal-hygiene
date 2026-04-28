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

    /// Round-17 wire: MedicationComplianceViewModel.doseHistory(...) loads
    /// completions over the trailing window and filters to medication blocks.
    @MainActor
    func test_viewModel_doseHistory_returnsMedicationCompletionsFromRollingWindow() async throws {
        let container = try AppModelContainer.makeInMemory()
        let repo = SwiftDataRoutineRepository(context: container.mainContext)

        let template = RoutineTemplate(name: "T", dayType: .weekday)
        try repo.upsert(template)
        let medBlock = Block(
            title: "Pill A",
            category: .medication,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 5,
            medicationConceptIdentifier: "concept-a"
        )
        let nonMedBlock = Block(
            title: "Brush teeth",
            category: .hygiene,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5
        )
        try repo.upsert(medBlock, in: template)
        try repo.upsert(nonMedBlock, in: template)

        let now = Date()
        try repo.markDone(medBlock, on: now)
        try repo.markDone(nonMedBlock, on: now)

        let viewModel = MedicationComplianceViewModel(
            service: InMemoryMedicationService(),
            repository: repo
        )
        let entries = viewModel.doseHistory(days: 30, now: now)

        XCTAssertEqual(entries.count, 1, "non-medication completions must be filtered out")
        XCTAssertEqual(entries.first?.blockTitle, "Pill A")
        XCTAssertEqual(entries.first?.conceptIdentifier, "concept-a")
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
