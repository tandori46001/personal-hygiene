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

    func test_revertDraft_resetsToTripValues() throws {
        let fix = try makeFixture()
        fix.viewModel.draftName = "Borrador"
        fix.viewModel.draftDestination = "Otro destino"
        XCTAssertTrue(fix.viewModel.hasChanges)

        fix.viewModel.revertDraft()

        XCTAssertEqual(fix.viewModel.draftName, fix.trip.name)
        XCTAssertEqual(fix.viewModel.draftDestination, fix.trip.destinationName)
        XCTAssertFalse(fix.viewModel.hasChanges)
    }

    func test_commitDraft_writesToTripAndPersists() throws {
        let fix = try makeFixture()
        fix.viewModel.draftName = "  Renombrado  "
        fix.viewModel.draftDestination = "Ibiza"
        fix.viewModel.commitDraft()

        XCTAssertEqual(fix.trip.name, "Renombrado")
        XCTAssertEqual(fix.trip.destinationName, "Ibiza")
        XCTAssertFalse(fix.viewModel.hasChanges)

        let trips = try fix.repo.allTrips()
        XCTAssertEqual(trips.first?.name, "Renombrado")
    }

    func test_commitDraft_blankNameIsNoop() throws {
        let fix = try makeFixture()
        let original = fix.trip.name
        fix.viewModel.draftName = "   "
        fix.viewModel.commitDraft()
        XCTAssertEqual(fix.trip.name, original)
    }

    func test_commitDraft_clampsEndBeforeStart() throws {
        let fix = try makeFixture()
        fix.viewModel.draftStartDate = Date(timeIntervalSince1970: 5_000_000)
        fix.viewModel.draftEndDate = Date(timeIntervalSince1970: 4_000_000)
        fix.viewModel.commitDraft()
        XCTAssertEqual(fix.trip.endDate, fix.trip.startDate)
    }

    func test_addMilestone_appendsTrimmedAndClampsDays() throws {
        let fix = try makeFixture()
        fix.viewModel.addMilestone(title: "  Pack  ", daysBefore: -3)

        XCTAssertEqual(fix.trip.milestones.count, 1)
        XCTAssertEqual(fix.trip.milestones.first?.title, "Pack")
        XCTAssertEqual(fix.trip.milestones.first?.daysBefore, 0)
    }

    func test_addMilestone_blankTitleIsNoop() throws {
        let fix = try makeFixture()
        fix.viewModel.addMilestone(title: "   ", daysBefore: 5)
        XCTAssertTrue(fix.trip.milestones.isEmpty)
    }

    func test_updateMilestone_appliesChanges() throws {
        let fix = try makeFixture()
        let milestone = TripMilestone(title: "Original", daysBefore: 3)
        try fix.repo.addMilestone(milestone, to: fix.trip)

        fix.viewModel.updateMilestone(milestone, title: "Updated", daysBefore: 14, isComplete: true)

        XCTAssertEqual(milestone.title, "Updated")
        XCTAssertEqual(milestone.daysBefore, 14)
        XCTAssertTrue(milestone.isComplete)
    }

    func test_toggleMilestoneCompletion_flipsBool() throws {
        let fix = try makeFixture()
        let milestone = TripMilestone(title: "Pack", daysBefore: 1)
        try fix.repo.addMilestone(milestone, to: fix.trip)

        fix.viewModel.toggleMilestoneCompletion(milestone)
        XCTAssertTrue(milestone.isComplete)

        fix.viewModel.toggleMilestoneCompletion(milestone)
        XCTAssertFalse(milestone.isComplete)
    }
}

@MainActor
final class TripsListViewModelArchiveTests: XCTestCase {

    // L001: hold the ModelContainer for the lifetime of the test. Returning
    // (vm, repo) from a helper without retaining `container` deallocates the
    // container the moment the helper returns; the next operation against
    // the orphaned context crashed the test process with a signal-trap.
    private var container: ModelContainer?

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private func makeListViewModel() throws -> (TripsListViewModel, SwiftDataTripsRepository) {
        let container = try AppModelContainer.makeInMemory()
        self.container = container
        let repo = SwiftDataTripsRepository(context: container.mainContext)
        let viewModel = TripsListViewModel(repository: repo)
        return (viewModel, repo)
    }

    func test_upcomingAndPastTrips_splitByEndDate() throws {
        let (vm, repo) = try makeListViewModel()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date!
        let pastTrip = Trip(
            name: "Past",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 1, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 1, day: 10).date!,
            destinationName: "X"
        )
        let activeTrip = Trip(
            name: "Active",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 4, day: 20).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 4, day: 30).date!,
            destinationName: "Y"
        )
        let futureTrip = Trip(
            name: "Future",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 6, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 6, day: 10).date!,
            destinationName: "Z"
        )
        try repo.upsert(pastTrip)
        try repo.upsert(activeTrip)
        try repo.upsert(futureTrip)
        vm.reload()

        let upcoming = vm.upcomingTrips(now: now, calendar: calendar)
        let past = vm.pastTrips(now: now, calendar: calendar)
        XCTAssertEqual(upcoming.map(\.name).sorted(), ["Active", "Future"])
        XCTAssertEqual(past.map(\.name), ["Past"])
    }

    func test_pastTrips_sortedByMostRecentlyEnded() throws {
        let (vm, repo) = try makeListViewModel()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = DateComponents(calendar: calendar, year: 2026, month: 4, day: 25).date!

        let trip1 = Trip(
            name: "Trip1",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 1, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 1, day: 5).date!,
            destinationName: "A"
        )
        let trip2 = Trip(
            name: "Trip2",
            startDate: DateComponents(calendar: calendar, year: 2026, month: 3, day: 1).date!,
            endDate: DateComponents(calendar: calendar, year: 2026, month: 3, day: 10).date!,
            destinationName: "B"
        )
        try repo.upsert(trip1)
        try repo.upsert(trip2)
        vm.reload()

        XCTAssertEqual(vm.pastTrips(now: now, calendar: calendar).map(\.name), ["Trip2", "Trip1"])
    }
}
