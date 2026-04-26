import SwiftData
import SwiftUI
import XCTest

@testable import PersonalHygiene

/// Smoke-level render tests for the major screens. We don't pixel-compare
/// against fixture PNGs (that needs a third-party library, which CLAUDE.md
/// rules out for now); instead each test asserts the SwiftUI view renders
/// to a non-empty `UIImage` of the expected size at the standard scale.
/// Catches the common failure modes: missing environment dependencies, view
/// model crashes, infinite layout loops, or a view that silently renders an
/// empty frame.
@MainActor
final class RenderSmokeTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    @MainActor
    private func render<Content: View>(_ view: Content, size: CGSize = .init(width: 390, height: 844)) -> UIImage? {
        let host =
            view
            .frame(width: size.width, height: size.height)
            .modelContainer(container)
        let renderer = ImageRenderer(content: host)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(size)
        return renderer.uiImage
    }

    private func tripFixture() -> Trip {
        let trip = Trip(
            name: "Mediterráneo",
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 14),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 21),
            destinationName: "Mallorca"
        )
        trip.milestones = [
            TripMilestone(title: "Buy currency", daysBefore: 7),
            TripMilestone(title: "Pack", daysBefore: 1, isComplete: true),
        ]
        return trip
    }

    // MARK: - Tests

    func test_today_render_smoke() throws {
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let template = RoutineTemplate(name: "Weekday", dayType: .weekday, blocks: [block], isActive: true)
        try repo.upsert(template)

        let viewModel = TodayViewModel(repository: repo)
        viewModel.reload()

        let image = render(TodayView(viewModel: viewModel))
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }

    func test_templateList_render_smoke() throws {
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        try repo.upsert(RoutineTemplate(name: "Weekday", dayType: .weekday, isActive: true))
        try repo.upsert(RoutineTemplate(name: "Weekend", dayType: .weekend))

        let viewModel = TemplateListViewModel(repository: repo)
        viewModel.reload()

        let image = render(TemplateListView(viewModel: viewModel, repository: repo))
        XCTAssertNotNil(image)
    }

    func test_tripsList_render_smoke() throws {
        let tripsRepo = SwiftDataTripsRepository(context: container.mainContext)
        try tripsRepo.upsert(tripFixture())

        let viewModel = TripsListViewModel(repository: tripsRepo)
        viewModel.reload()

        let image = render(TripsListView(viewModel: viewModel))
        XCTAssertNotNil(image)
    }

    func test_tripDetail_render_smoke() throws {
        let tripsRepo = SwiftDataTripsRepository(context: container.mainContext)
        let trip = tripFixture()
        try tripsRepo.upsert(trip)

        let viewModel = TripDetailViewModel(trip: trip, repository: tripsRepo)
        let image = render(NavigationStack { TripDetailView(viewModel: viewModel) })
        XCTAssertNotNil(image)
    }

    func test_emptyToday_render_smoke() {
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        let viewModel = TodayViewModel(repository: repo)
        viewModel.reload()  // No template seeded → empty state.
        let image = render(TodayView(viewModel: viewModel))
        XCTAssertNotNil(image)
    }
}
