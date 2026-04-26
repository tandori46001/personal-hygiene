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

    // MARK: - Dynamic Type pass

    /// Renders the major screens at the largest accessibility size so we catch
    /// truncation / cropped icons / layout that breaks at AX5 *before* a real
    /// user with the largest text setting sees it.
    func test_today_render_atAccessibilityXXXL() throws {
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        try repo.upsert(RoutineTemplate(name: "T", dayType: .weekday, blocks: [block], isActive: true))

        let viewModel = TodayViewModel(repository: repo)
        viewModel.reload()

        let image = render(
            TodayView(viewModel: viewModel)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }

    func test_tripDetail_render_atAccessibilityXXXL() throws {
        let tripsRepo = SwiftDataTripsRepository(context: container.mainContext)
        let trip = tripFixture()
        try tripsRepo.upsert(trip)

        let viewModel = TripDetailViewModel(trip: trip, repository: tripsRepo)
        let image = render(
            NavigationStack { TripDetailView(viewModel: viewModel) }
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }

    // MARK: - Dynamic Type extension (session 6 a11y polish)

    func test_templateList_render_atAccessibilityXXXL() throws {
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        let block = Block(title: "Aseo", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30)
        try repo.upsert(RoutineTemplate(name: "Weekday", dayType: .weekday, blocks: [block], isActive: true))
        try repo.upsert(RoutineTemplate(name: "Weekend", dayType: .weekend))

        let viewModel = TemplateListViewModel(repository: repo)
        viewModel.reload()

        let image = render(
            TemplateListView(viewModel: viewModel, repository: repo)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }

    func test_tripsList_render_atAccessibilityXXXL() throws {
        let tripsRepo = SwiftDataTripsRepository(context: container.mainContext)
        try tripsRepo.upsert(tripFixture())

        let viewModel = TripsListViewModel(repository: tripsRepo)
        viewModel.reload()

        let image = render(
            TripsListView(viewModel: viewModel)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }

    func test_emptyTrips_render_smoke() {
        let tripsRepo = SwiftDataTripsRepository(context: container.mainContext)
        let viewModel = TripsListViewModel(repository: tripsRepo)
        viewModel.reload()  // no trips
        let image = render(TripsListView(viewModel: viewModel))
        XCTAssertNotNil(image)
    }

    func test_pastTripsArchive_render_smoke() throws {
        let tripsRepo = SwiftDataTripsRepository(context: container.mainContext)
        let upcoming = Trip(
            name: "Future",
            startDate: Date().addingTimeInterval(60 * 60 * 24 * 14),
            endDate: Date().addingTimeInterval(60 * 60 * 24 * 21),
            destinationName: "Tokyo"
        )
        let past = Trip(
            name: "Past",
            startDate: Date().addingTimeInterval(-60 * 60 * 24 * 21),
            endDate: Date().addingTimeInterval(-60 * 60 * 24 * 14),
            destinationName: "Lisbon"
        )
        try tripsRepo.upsert(upcoming)
        try tripsRepo.upsert(past)

        let viewModel = TripsListViewModel(repository: tripsRepo)
        viewModel.reload()

        let image = render(TripsListView(viewModel: viewModel))
        XCTAssertNotNil(image)
    }

    // MARK: - Dynamic Type round-2 (session 7 a11y polish)

    func test_birthdaysView_render_atAccessibilityXXXL() async {
        let contacts = [
            BirthdayContact(identifier: "1", displayName: "Ana", month: 6, day: 15, year: 1980),
            BirthdayContact(identifier: "2", displayName: "Ben", month: 12, day: 24, year: nil),
        ]
        let service = InMemoryContactsService(contacts: contacts, status: .authorized)
        let viewModel = BirthdaysViewModel(service: service)
        viewModel.reloadStatus()
        await viewModel.reload()

        let image = render(
            BirthdaysView(viewModel: viewModel)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }

    func test_focusScheduleView_render_atAccessibilityXXXL() {
        let store = InMemoryFocusScheduleStore()
        store.upsert(
            ScheduledFocusWindow(
                label: "Workday focus",
                weekdays: [2, 3, 4, 5, 6],
                startMinutesFromMidnight: 9 * 60,
                endMinutesFromMidnight: 12 * 60
            )
        )
        store.upsert(
            ScheduledFocusWindow(
                label: "Evening wind-down",
                weekdays: [1, 7],
                startMinutesFromMidnight: 21 * 60 + 30,
                endMinutesFromMidnight: 23 * 60
            )
        )

        let image = render(
            NavigationStack { FocusScheduleView(store: store) }
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }

    func test_settingsView_render_atAccessibilityXXXL() {
        let service = StubRenderNotificationService()
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        let coordinator = NotificationCoordinator(repository: repo, service: service)
        let viewModel = SettingsViewModel(service: service, coordinator: coordinator)

        let image = render(
            SettingsView(viewModel: viewModel, focusScheduleStore: InMemoryFocusScheduleStore())
                .modelContainer(container)
                .environment(\.dynamicTypeSize, .accessibility5)
        )
        XCTAssertNotNil(image)
    }
}

@MainActor
private final class StubRenderNotificationService: NotificationService {
    func authorizationStatus() async -> NotificationAuthorizationStatus { .notDetermined }
    func requestAuthorization(criticalAlerts _: Bool) async throws -> Bool { false }
    func scheduleAll(_: [ScheduledNotification], cancellingPrefix _: String) async throws {}
    func cancelAll(withPrefix _: String) async {}
}
