@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class TripDetailViewModelRound12Tests: XCTestCase {

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

    func test_completionFraction_nilWhenEmpty() {
        let trip = Trip(
            name: "Empty",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Madrid"
        )
        let viewModel = makeViewModel(trip)
        XCTAssertNil(viewModel.completionFraction())
    }

    func test_completionFraction_packingAndMilestones() {
        let trip = Trip(
            name: "Sample",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Madrid",
            packingItems: [
                PackingItem(title: "Toothbrush", isPacked: true),
                PackingItem(title: "Passport", isPacked: false),
            ]
        )
        let viewModel = makeViewModel(trip)
        // 1 of 2 packed, 0 milestones → 1/2 = 0.5
        XCTAssertEqual(viewModel.completionFraction() ?? -1, 0.5, accuracy: 0.01)
    }

    func test_filteredSortedPackingItems_byCategory() {
        let trip = Trip(
            name: "Sample",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86_400),
            destinationName: "Madrid",
            packingItems: [
                PackingItem(title: "Shirt", isPacked: false, category: .clothing),
                PackingItem(title: "Charger", isPacked: false, category: .electronics),
            ]
        )
        let viewModel = makeViewModel(trip)
        viewModel.packingCategoryFilter = .clothing
        XCTAssertEqual(viewModel.filteredSortedPackingItems.count, 1)
        XCTAssertEqual(viewModel.filteredSortedPackingItems.first?.title, "Shirt")
        viewModel.packingCategoryFilter = nil
        XCTAssertEqual(viewModel.filteredSortedPackingItems.count, 2)
    }

    func test_archiveNow_movesEndDateToYesterday() {
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let trip = Trip(
            name: "Sample",
            startDate: now,
            endDate: cal.date(byAdding: .day, value: 7, to: now)!,
            destinationName: "Madrid"
        )
        let viewModel = makeViewModel(trip)
        XCTAssertTrue(viewModel.isStillActive(now: now, calendar: cal))
        viewModel.archiveNow(now: now, calendar: cal)
        XCTAssertFalse(viewModel.isStillActive(now: now, calendar: cal))
    }
}
