import SwiftData
import XCTest

@testable import PersonalHygiene

@MainActor
final class BackupServiceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    private func seedSampleData() throws {
        let context = container.mainContext
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30,
            notes: "Brush + shower"
        )
        let template = RoutineTemplate(
            name: "Weekday",
            dayType: .weekday,
            blocks: [block],
            isActive: true
        )
        context.insert(template)
        context.insert(HydrationLog(milliliters: 250, drankAt: Date(timeIntervalSince1970: 1_700_000_000)))
        context.insert(
            HousekeepingTask(title: "Vacuum", recurrence: .weekly)
        )
        let trip = Trip(
            name: "Mediterráneo",
            startDate: Date(timeIntervalSince1970: 2_000_000_000),
            endDate: Date(timeIntervalSince1970: 2_001_000_000),
            destinationName: "Mallorca",
            milestones: [TripMilestone(title: "Pack", daysBefore: 1)]
        )
        context.insert(trip)
        try context.save()
    }

    func test_export_capturesAllSyncableData() throws {
        try seedSampleData()
        let snapshot = try BackupService.export(from: container.mainContext)

        XCTAssertEqual(snapshot.templates.count, 1)
        XCTAssertEqual(snapshot.templates.first?.blocks.count, 1)
        XCTAssertEqual(snapshot.hydration.count, 1)
        XCTAssertEqual(snapshot.housekeeping.count, 1)
        XCTAssertEqual(snapshot.trips.count, 1)
        XCTAssertEqual(snapshot.trips.first?.milestones.count, 1)
    }

    func test_encodeDecode_roundtripPreservesAllFields() throws {
        try seedSampleData()
        let original = try BackupService.export(from: container.mainContext)
        let data = try BackupService.encode(original)
        let decoded = try BackupService.decode(data)
        // Compare by re-encoding both halves to JSON; Date == is fragile under
        // 1970-vs-2001 reference rebasing through Double, but the on-disk
        // representation is what users actually see / restore from.
        let reEncoded = try BackupService.encode(decoded)
        XCTAssertEqual(data, reEncoded)
        XCTAssertEqual(original.templates, decoded.templates)
        XCTAssertEqual(original.housekeeping, decoded.housekeeping)
    }

    func test_restore_replacesAllData() throws {
        try seedSampleData()
        let snapshot = try BackupService.export(from: container.mainContext)

        // Mutate state: add a template that should be wiped on restore.
        container.mainContext.insert(
            RoutineTemplate(name: "Weekend", dayType: .weekend)
        )
        try container.mainContext.save()

        try BackupService.restore(snapshot, into: container.mainContext)

        let templates = try container.mainContext.fetch(FetchDescriptor<RoutineTemplate>())
        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.name, "Weekday")
    }
}
