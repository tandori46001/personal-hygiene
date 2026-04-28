@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class BackupSizeProjectorTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    func test_projectedSize_isPositiveForSeededContainer() throws {
        let context = container.mainContext
        context.insert(RoutineTemplate(name: "Weekday", dayType: .weekday, blocks: []))
        try context.save()
        let bytes = BackupSizeProjector.projectedSize(from: context)
        XCTAssertNotNil(bytes)
        XCTAssertGreaterThan(bytes ?? 0, 0)
    }

    func test_projectedSize_emptyContainerStillReturnsBytes() throws {
        // Even an empty container produces a JSON envelope (templates: [],
        // hydration: [], …). Should be > 0 because of the JSON skeleton.
        let bytes = BackupSizeProjector.projectedSize(from: container.mainContext)
        XCTAssertNotNil(bytes)
        XCTAssertGreaterThan(bytes ?? 0, 0)
    }

    func test_formatted_renderHumanReadable() {
        let label = BackupSizeProjector.formatted(12_345)
        // ByteCountFormatter renders 12 KB or 13 KB depending on rounding.
        XCTAssertTrue(label.contains("KB"))
    }
}
