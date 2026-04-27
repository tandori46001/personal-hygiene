@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class TripDetailViewModelRound13Tests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataTripsRepository!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Trip.self, TripMilestone.self, TripDocument.self,
            configurations: config
        )
        repository = SwiftDataTripsRepository(context: container.mainContext)
    }

    override func tearDown() {
        repository = nil
        container = nil
    }

    private func makeViewModel(_ trip: Trip) -> TripDetailViewModel {
        try? repository.upsert(trip)
        return TripDetailViewModel(trip: trip, repository: repository)
    }

    func test_notesParagraphs_splitsByBlankLines() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Y",
            notes: "First paragraph.\n\nSecond paragraph.\n\nThird"
        )
        let viewModel = makeViewModel(trip)
        XCTAssertEqual(viewModel.notesParagraphs, [
            "First paragraph.",
            "Second paragraph.",
            "Third"
        ])
    }

    func test_notesParagraphs_emptyOnBlankNotes() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Y",
            notes: "   "
        )
        let viewModel = makeViewModel(trip)
        XCTAssertTrue(viewModel.notesParagraphs.isEmpty)
    }

    func test_addExpense_persists() {
        let trip = Trip(
            name: "X",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Y"
        )
        let viewModel = makeViewModel(trip)
        viewModel.addExpense(label: "Hotel", amount: 120, currencyCode: "usd")
        XCTAssertEqual(viewModel.expenses.count, 1)
        XCTAssertEqual(viewModel.expenses.first?.currencyCode, "USD")
    }

    func test_itineraryMarkdown_includesNotesAndPacking() {
        let trip = Trip(
            name: "Tokyo",
            startDate: Date(timeIntervalSince1970: 1_777_000_000),
            endDate: Date(timeIntervalSince1970: 1_777_600_000),
            destinationName: "Tokyo",
            packingItems: [PackingItem(title: "Passport", isPacked: true)],
            notes: "Bring extra cash."
        )
        let viewModel = makeViewModel(trip)
        let md = viewModel.itineraryMarkdown()
        XCTAssertTrue(md.contains("# Tokyo"))
        XCTAssertTrue(md.contains("## Packing"))
        XCTAssertTrue(md.contains("[x] Passport"))
        XCTAssertTrue(md.contains("Bring extra cash."))
    }

    func test_duplicateShifted_movesDates() {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let end = cal.date(from: DateComponents(year: 2026, month: 5, day: 7))!
        let original = Trip(name: "X", startDate: start, endDate: end, destinationName: "Y")
        let copy = TripDetailViewModel.duplicateShifted(original, byDays: 30, calendar: cal)
        XCTAssertEqual(
            cal.dateComponents([.day], from: original.startDate, to: copy.startDate).day,
            30
        )
        XCTAssertEqual(copy.name, "Copy of X")
    }
}
