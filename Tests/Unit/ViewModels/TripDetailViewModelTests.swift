import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class TripDetailViewModelTests: XCTestCase {

    private struct Fixture {
        let container: ModelContainer
        let repo: SwiftDataTripsRepository
        let viewModel: TripDetailViewModel
        let trip: Trip
    }

    private func makeFixture() throws -> Fixture {
        let container = try AppModelContainer.makeInMemory()
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        let trip = Trip(
            name: "Mediterráneo",
            startDate: Date(timeIntervalSince1970: 1_000_000),
            endDate: Date(timeIntervalSince1970: 2_000_000),
            destinationName: "Mallorca"
        )
        try repo.upsert(trip)
        let viewModel = TripDetailViewModel(trip: trip, repository: repo)
        return Fixture(container: container, repo: repo, viewModel: viewModel, trip: trip)
    }

    func test_sortedMilestones_orderedByDaysBeforeDescending() throws {
        let fix = try makeFixture()
        let m1 = TripMilestone(title: "Confirm hotel", daysBefore: 30)
        let m2 = TripMilestone(title: "Pack", daysBefore: 1)
        let m3 = TripMilestone(title: "Buy currency", daysBefore: 7)
        try fix.repo.addMilestone(m1, to: fix.trip)
        try fix.repo.addMilestone(m2, to: fix.trip)
        try fix.repo.addMilestone(m3, to: fix.trip)

        XCTAssertEqual(fix.viewModel.sortedMilestones.map(\.title), ["Confirm hotel", "Buy currency", "Pack"])
    }

    func test_deleteMilestone_removesFromTrip() throws {
        let fix = try makeFixture()
        let milestone = TripMilestone(title: "Pack", daysBefore: 1)
        try fix.repo.addMilestone(milestone, to: fix.trip)

        fix.viewModel.deleteMilestone(milestone)

        XCTAssertTrue(fix.trip.milestones.isEmpty)
    }

    func test_daysUntilDeparture_returnsPositiveWhenInFuture() throws {
        let fix = try makeFixture()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date!
        let target = DateComponents(calendar: calendar, year: 2026, month: 5, day: 5).date!
        fix.trip.startDate = target

        XCTAssertEqual(fix.viewModel.daysUntilDeparture(now: now, calendar: calendar), 10)
    }

    func test_saveEdits_persistsChanges() throws {
        let fix = try makeFixture()
        fix.viewModel.trip.name = "Renombrado"
        fix.viewModel.saveEdits()

        let trips = try fix.repo.allTrips()
        XCTAssertEqual(trips.first?.name, "Renombrado")
    }
}
