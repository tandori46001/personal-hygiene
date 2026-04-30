import SwiftData
@preconcurrency import XCTest

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

    // MARK: - v1.1 packing items (session 5 → tests added session 6)

    func test_packingItems_roundtripThroughBackup() throws {
        let context = container.mainContext
        let trip = Trip(
            name: "Roma",
            startDate: Date(timeIntervalSince1970: 2_000_000_000),
            endDate: Date(timeIntervalSince1970: 2_001_000_000),
            destinationName: "Roma",
            packingItems: [
                PackingItem(title: "Pasaporte", isPacked: false),
                PackingItem(title: "Crema solar", isPacked: true),
            ],
            milestones: []
        )
        context.insert(trip)
        try context.save()

        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertEqual(snapshot.trips.first?.packingItems?.count, 2)

        // Round-trip through restore on a clean context.
        try BackupService.restore(snapshot, into: container.mainContext)
        let restoredTrips = try container.mainContext.fetch(FetchDescriptor<Trip>())
        XCTAssertEqual(restoredTrips.count, 1)
        let titles = restoredTrips.first?.packingItems.map(\.title).sorted()
        XCTAssertEqual(titles, ["Crema solar", "Pasaporte"])
        let packed = restoredTrips.first?.packingItems.first(where: { $0.title == "Crema solar" })?.isPacked
        XCTAssertEqual(packed, true)
    }

    func test_decode_v1Backup_withoutPackingItems_succeeds() throws {
        // Hand-crafted minimal v1 JSON (pre-packing-items). The decoder must
        // accept it because `packingItems` is optional.
        let jsonString = """
        {
          "version": 1,
          "exportedAt": 1700000000.0,
          "templates": [],
          "completions": [],
          "hydration": [],
          "housekeeping": [],
          "trips": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "name": "Old trip",
              "startDate": 2000000000.0,
              "endDate": 2001000000.0,
              "destinationName": "Lisbon",
              "destinationLatitude": null,
              "destinationLongitude": null,
              "milestones": []
            }
          ]
        }
        """
        let json = Data(jsonString.utf8)

        let decoded = try BackupService.decode(json)
        XCTAssertEqual(decoded.trips.count, 1)
        XCTAssertNil(decoded.trips.first?.packingItems)

        try BackupService.restore(decoded, into: container.mainContext)
        let restored = try container.mainContext.fetch(FetchDescriptor<Trip>())
        XCTAssertEqual(restored.count, 1)
        XCTAssertTrue(restored.first?.packingItems.isEmpty ?? false)
    }

    // MARK: - v1.1 → v1 downgrade safety (slice 12)

    /// Guards that a v1.1 backup can have its `packingItems` field stripped
    /// (simulating an older v1-era importer) without losing any of the v1-era
    /// data: templates, hydration, housekeeping, trips, milestones,
    /// completions. Catches regressions where new fields accidentally take
    /// load-bearing duties.
    func test_v11Backup_strippedToV1_keepsEveryUserVisibleItem() throws {
        try seedSampleData()
        let context = container.mainContext
        let trip = try context.fetch(FetchDescriptor<Trip>()).first
        trip?.packingItems = [
            PackingItem(title: "Pasaporte", isPacked: false),
            PackingItem(title: "Crema solar", isPacked: true),
        ]
        try context.save()

        let v11 = try BackupService.export(from: context)
        var json = try JSONSerialization.jsonObject(with: BackupService.encode(v11)) as? [String: Any] ?? [:]
        if var trips = json["trips"] as? [[String: Any]] {
            for index in trips.indices {
                trips[index].removeValue(forKey: "packingItems")
            }
            json["trips"] = trips
        }
        let downgraded = try JSONSerialization.data(withJSONObject: json)

        let decoded = try BackupService.decode(downgraded)
        XCTAssertEqual(decoded.templates.count, v11.templates.count)
        XCTAssertEqual(decoded.templates.first?.blocks.count, v11.templates.first?.blocks.count)
        XCTAssertEqual(decoded.hydration.count, v11.hydration.count)
        XCTAssertEqual(decoded.housekeeping.count, v11.housekeeping.count)
        XCTAssertEqual(decoded.trips.count, v11.trips.count)
        XCTAssertEqual(decoded.trips.first?.milestones.count, v11.trips.first?.milestones.count)
        XCTAssertNil(decoded.trips.first?.packingItems)
    }
}
