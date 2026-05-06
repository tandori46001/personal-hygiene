import SwiftData
@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class TripsListViewModelSearchTests: XCTestCase {

    // L001 guard.
    private var container: ModelContainer?

    private func makeFixture() throws -> (TripsListViewModel, SwiftDataTripsRepository) {
        let container = try AppModelContainer.makeInMemory()
        self.container = container
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        let vm = TripsListViewModel(repository: repo)
        for trip in [
            Trip(name: "Mediterranean", startDate: Date(timeIntervalSince1970: 1_000_000),
                 endDate: Date(timeIntervalSince1970: 2_000_000), destinationName: "Mallorca"),
            Trip(name: "Asia tour", startDate: Date(timeIntervalSince1970: 1_500_000),
                 endDate: Date(timeIntervalSince1970: 3_000_000), destinationName: "Tokyo"),
            Trip(name: "Family Spain trip", startDate: Date(timeIntervalSince1970: 1_700_000),
                 endDate: Date(timeIntervalSince1970: 1_800_000), destinationName: "Madrid"),
        ] {
            try repo.upsert(trip)
        }
        vm.reload()
        return (vm, repo)
    }

    func test_filtered_emptyQueryReturnsAll() throws {
        let (vm, _) = try makeFixture()
        vm.searchQuery = ""
        XCTAssertEqual(vm.filtered(vm.trips).count, vm.trips.count)
    }

    func test_filtered_matchesByName() throws {
        let (vm, _) = try makeFixture()
        vm.searchQuery = "med"
        let result = vm.filtered(vm.trips)
        XCTAssertEqual(result.map(\.name), ["Mediterranean"])
    }

    func test_filtered_matchesByDestination() throws {
        let (vm, _) = try makeFixture()
        vm.searchQuery = "tokyo"
        XCTAssertEqual(vm.filtered(vm.trips).map(\.name), ["Asia tour"])
    }

    func test_filtered_caseInsensitive() throws {
        let (vm, _) = try makeFixture()
        vm.searchQuery = "SPAIN"
        XCTAssertEqual(vm.filtered(vm.trips).map(\.name), ["Family Spain trip"])
    }

    func test_filtered_trimsWhitespace() throws {
        let (vm, _) = try makeFixture()
        vm.searchQuery = "   "
        XCTAssertEqual(vm.filtered(vm.trips).count, vm.trips.count)
    }
}

@MainActor
final class TripDetailViewModelNextMilestoneTests: XCTestCase {

    private var container: ModelContainer?

    private struct MilestoneSpec {
        let title: String
        let daysBefore: Int
        let complete: Bool
    }

    private func makeViewModel(
        milestones: [MilestoneSpec]
    ) throws -> (TripDetailViewModel, Trip) {
        let container = try AppModelContainer.makeInMemory()
        self.container = container
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let trip = Trip(
            name: "Trip",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 6, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 6, day: 10).date!,
            destinationName: "X"
        )
        try repo.upsert(trip)
        for spec in milestones {
            try repo.addMilestone(
                TripMilestone(title: spec.title, daysBefore: spec.daysBefore, isComplete: spec.complete),
                to: trip
            )
        }
        return (TripDetailViewModel(trip: trip, repository: repo), trip)
    }

    func test_nextDueMilestone_pickSoonestIncomplete() throws {
        let (vm, _) = try makeViewModel(milestones: [
            MilestoneSpec(title: "Confirm hotel", daysBefore: 30, complete: false),
            MilestoneSpec(title: "Pack", daysBefore: 1, complete: false),
            MilestoneSpec(title: "Buy currency", daysBefore: 7, complete: false),
        ])
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 1).date!
        let result = vm.nextDueMilestone(now: now, calendar: calendar)
        XCTAssertEqual(result?.title, "Pack")
    }

    func test_nextDueMilestone_skipsCompleted() throws {
        let (vm, _) = try makeViewModel(milestones: [
            MilestoneSpec(title: "Pack", daysBefore: 1, complete: true),
            MilestoneSpec(title: "Confirm hotel", daysBefore: 30, complete: false),
        ])
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 1).date!
        XCTAssertEqual(vm.nextDueMilestone(now: now, calendar: calendar)?.title, "Confirm hotel")
    }

    func test_nextDueMilestone_returnsNilWhenAllComplete() throws {
        let (vm, _) = try makeViewModel(milestones: [
            MilestoneSpec(title: "Pack", daysBefore: 1, complete: true),
        ])
        XCTAssertNil(vm.nextDueMilestone())
    }

    func test_packingBulkActions() throws {
        let container = try AppModelContainer.makeInMemory()
        self.container = container
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        let trip = Trip(name: "T", startDate: Date(), endDate: Date(), destinationName: "X")
        trip.packingItems = [
            PackingItem(title: "Passport", isPacked: false),
            PackingItem(title: "Charger", isPacked: false),
        ]
        try repo.upsert(trip)
        let vm = TripDetailViewModel(trip: trip, repository: repo)

        vm.markAllPacked()
        XCTAssertTrue(trip.packingItems.allSatisfy(\.isPacked))

        vm.resetAllPacking()
        XCTAssertTrue(trip.packingItems.allSatisfy { !$0.isPacked })
    }
}
