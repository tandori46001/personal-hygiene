@testable import PersonalHygiene
import SwiftData
import XCTest

@MainActor
final class BackupSnapshotV5ArchiveTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        TemplateArchiveStore.clear()
    }

    override func tearDown() async throws {
        TemplateArchiveStore.clear()
        container = nil
        try await super.tearDown()
    }

    func test_export_includesArchivedIDsWhenSet() throws {
        let id = UUID()
        TemplateArchiveStore.setArchived(true, for: id)
        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertEqual(snapshot.archivedTemplateIDs?.count, 1)
        XCTAssertEqual(snapshot.archivedTemplateIDs?.first, id)
        XCTAssertGreaterThanOrEqual(snapshot.version, 5)
    }

    func test_export_omitsArchiveWhenEmpty() throws {
        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertNil(snapshot.archivedTemplateIDs)
    }

    func test_restore_replaysArchivedIDs() throws {
        let id = UUID()
        TemplateArchiveStore.setArchived(true, for: id)
        let snapshot = try BackupService.export(from: container.mainContext)
        TemplateArchiveStore.clear()
        XCTAssertTrue(TemplateArchiveStore.archivedIDs().isEmpty)

        try BackupService.restore(snapshot, into: container.mainContext)

        XCTAssertTrue(TemplateArchiveStore.isArchived(id))
    }

    func test_v4Backup_strippedOfArchive_decodesCleanly() throws {
        TemplateArchiveStore.setArchived(true, for: UUID())
        let v5 = try BackupService.export(from: container.mainContext)
        var json = try JSONSerialization.jsonObject(with: BackupService.encode(v5)) as? [String: Any] ?? [:]
        json.removeValue(forKey: "archivedTemplateIDs")
        let downgraded = try JSONSerialization.data(withJSONObject: json)

        let decoded = try BackupService.decode(downgraded)
        XCTAssertNil(decoded.archivedTemplateIDs)
    }
}
