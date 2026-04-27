import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class TripsListViewModelDuplicationTests: XCTestCase {

    // L001 guard.
    private var container: ModelContainer?

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private struct Fixture {
        let viewModel: TripsListViewModel
        let repo: SwiftDataTripsRepository
        let trip: Trip
    }

    private func makeFixture() throws -> Fixture {
        let container = try AppModelContainer.makeInMemory()
        self.container = container
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        let trip = Trip(
            name: "Original",
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_000),
            destinationName: "Lisboa"
        )
        trip.packingItems = [
            PackingItem(title: "Passport", isPacked: true),
            PackingItem(title: "Toothbrush", isPacked: false),
        ]
        try repo.upsert(trip)
        try repo.addMilestone(TripMilestone(title: "Pack", daysBefore: 1), to: trip)
        try repo.addMilestone(TripMilestone(title: "Confirm hotel", daysBefore: 30), to: trip)
        let vm = TripsListViewModel(repository: repo)
        return Fixture(viewModel: vm, repo: repo, trip: trip)
    }

    func test_duplicate_clonesPackingItemsResettingPacked() throws {
        let fix = try makeFixture()
        fix.viewModel.duplicate(fix.trip)
        let trips = try fix.repo.allTrips()
        XCTAssertEqual(trips.count, 2)
        let copy = trips.first { $0.name.hasPrefix("Copy of ") }
        XCTAssertNotNil(copy)
        XCTAssertEqual(copy?.packingItems.count, 2)
        XCTAssertTrue(copy?.packingItems.allSatisfy { !$0.isPacked } ?? false)
    }

    func test_duplicate_clonesMilestonesAsIncomplete() throws {
        let fix = try makeFixture()
        fix.viewModel.duplicate(fix.trip)
        let trips = try fix.repo.allTrips()
        let copy = trips.first { $0.name.hasPrefix("Copy of ") }
        XCTAssertEqual(copy?.milestones.count, 2)
        XCTAssertTrue(copy?.milestones.allSatisfy { !$0.isComplete } ?? false)
    }

    func test_daysUntilNearest_returnsClosestUpcomingTrip() throws {
        let fix = try makeFixture()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date!

        let near = Trip(
            name: "Near",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 5, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 5, day: 8).date!,
            destinationName: "X"
        )
        let far = Trip(
            name: "Far",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 7, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 7, day: 8).date!,
            destinationName: "Y"
        )
        try fix.repo.upsert(near)
        try fix.repo.upsert(far)
        fix.viewModel.reload()

        let result = fix.viewModel.daysUntilNearest(now: now, calendar: calendar)
        XCTAssertEqual(result?.0.name, "Near")
        XCTAssertEqual(result?.1, 6)
    }

    func test_duplicate_static_doesNotShareReferences() {
        let trip = Trip(
            name: "Original",
            startDate: Date(),
            endDate: Date(),
            destinationName: "X"
        )
        trip.packingItems = [PackingItem(title: "Pack", isPacked: true)]
        let copy = TripsListViewModel.duplicate(trip)
        XCTAssertEqual(copy.name, "Copy of Original")
        XCTAssertEqual(copy.packingItems.count, 1)
        XCTAssertFalse(copy.packingItems[0].isPacked)
        // Mutating the copy's packing list must not bleed into the original.
        copy.packingItems[0].isPacked = true
        XCTAssertTrue(trip.packingItems[0].isPacked, "original was already packed")
        XCTAssertNotEqual(copy.id, trip.id)
    }
}
