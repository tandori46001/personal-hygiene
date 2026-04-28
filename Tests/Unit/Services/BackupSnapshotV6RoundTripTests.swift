@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class BackupSnapshotV6RoundTripTests: XCTestCase {

    private var container: ModelContainer!
    private let suite = "v6Tests-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        HousekeepingCompletionLog.clear(in: defaults)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        container = nil
        try await super.tearDown()
    }

    func test_export_includesHousekeepingLogWhenPresent() throws {
        HousekeepingCompletionLog.record(
            room: "kitchen",
            on: Date(timeIntervalSince1970: 1_745_000_000),
            in: defaults
        )
        let payload = BackupService.housekeepingLogPayload(in: defaults)
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?["kitchen"]?.count, 1)
    }

    func test_export_emitsNilWhenLogEmpty() throws {
        let payload = BackupService.housekeepingLogPayload(in: defaults)
        XCTAssertNil(payload)
    }

    func test_v6Snapshot_isVersion6() throws {
        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertGreaterThanOrEqual(snapshot.version, 6)
    }

    func test_v5Backup_decodesCleanlyWithoutHousekeepingField() throws {
        let snapshot = try BackupService.export(from: container.mainContext)
        var json = try JSONSerialization.jsonObject(with: BackupService.encode(snapshot)) as? [String: Any] ?? [:]
        json.removeValue(forKey: "housekeepingCompletionLog")
        let downgraded = try JSONSerialization.data(withJSONObject: json)
        let decoded = try BackupService.decode(downgraded)
        XCTAssertNil(decoded.housekeepingCompletionLog)
    }
}
