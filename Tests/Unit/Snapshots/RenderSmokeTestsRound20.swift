@testable import PersonalHygiene
import SwiftData
import SwiftUI
@preconcurrency import XCTest

/// Round-20 slices T1.2 + T1.3 — extracted from `RenderSmokeTests` to keep
/// that class body under SwiftLint's `type_body_length` cap.
@MainActor
final class RenderSmokeTestsRound20: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    @MainActor
    private func render<Content: View>(
        _ view: Content,
        size: CGSize = .init(width: 390, height: 844)
    ) -> UIImage? {
        let host =
            view
            .frame(width: size.width, height: size.height)
            .modelContainer(container)
        let renderer = ImageRenderer(content: host)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(size)
        return renderer.uiImage
    }

    // MARK: - T1.2 perpetual-deferred snapshot lab smokes

    func test_advisoryView_render_smoke() {
        guard let url = URL(string: "https://example.com/advisory/es") else {
            XCTFail("advisory URL"); return
        }
        let link = TravelAdvisoryLink(
            displayName: "Spain (exteriores.gob.es)",
            url: url,
            source: "exteriores.gob.es"
        )
        XCTAssertNotNil(render(NavigationStack { AdvisoryView(link: link) }))
    }

    func test_currencyView_render_smoke_quickPick() {
        let service = StubRenderRound20Currency()
        XCTAssertNotNil(render(NavigationStack { CurrencyView(service: service) }))
    }

    func test_hydrationDashboard_emptyChart_render_smoke() {
        let service = SwiftDataHydrationService(context: container.mainContext)
        let viewModel = HydrationDashboardViewModel(service: service)
        XCTAssertNotNil(render(HydrationDashboardView(viewModel: viewModel)))
    }

    // MARK: - T1.3 DynamicType regression suite extension

    func test_advisoryView_render_atAccessibilityXXXL() {
        guard let url = URL(string: "https://example.com/advisory/es") else {
            XCTFail("advisory URL"); return
        }
        let link = TravelAdvisoryLink(
            displayName: "Spain (exteriores.gob.es)",
            url: url,
            source: "exteriores.gob.es"
        )
        XCTAssertNotNil(render(
            NavigationStack { AdvisoryView(link: link) }
                .environment(\.dynamicTypeSize, .accessibility5)
        ))
    }

    func test_currencyView_render_atAccessibilityXXXL() {
        let service = StubRenderRound20Currency()
        XCTAssertNotNil(render(
            NavigationStack { CurrencyView(service: service) }
                .environment(\.dynamicTypeSize, .accessibility5)
        ))
    }

    func test_hydrationDashboard_render_atAccessibilityXXXL() {
        let service = SwiftDataHydrationService(context: container.mainContext)
        let viewModel = HydrationDashboardViewModel(service: service)
        XCTAssertNotNil(render(
            HydrationDashboardView(viewModel: viewModel)
                .environment(\.dynamicTypeSize, .accessibility5)
        ))
    }

    func test_templateEditor_render_atAccessibilityXXXL() throws {
        let repo = SwiftDataRoutineRepository(context: container.mainContext)
        let template = RoutineTemplate(name: "T", dayType: .weekday)
        try repo.upsert(template)
        try repo.upsert(
            Block(title: "Aseo", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 30),
            in: template
        )
        try repo.upsert(
            Block(title: "Trabajo", category: .work, startMinutesFromMidnight: 9 * 60, durationMinutes: 60),
            in: template
        )
        let viewModel = TemplateEditorViewModel(template: template, repository: repo)
        XCTAssertNotNil(render(
            NavigationStack { TemplateEditorView(viewModel: viewModel) }
                .environment(\.dynamicTypeSize, .accessibility5)
        ))
    }
}

private struct StubRenderRound20Currency: CurrencyService {
    func convert(amount: Double, from: String, to: String) async throws -> CurrencyConversion {
        CurrencyConversion(from: from, to: to, rate: 1.1, amountConverted: amount * 1.1)
    }
}
