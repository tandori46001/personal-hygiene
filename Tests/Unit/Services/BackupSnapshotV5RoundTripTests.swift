@testable import PersonalHygiene
import SwiftData
@preconcurrency import XCTest

/// Round-25 slice T1.1: deeper round-trip than `BackupSnapshotV5ArchiveTests`
/// — encodes, decodes, restores into a fresh container, and re-exports to
/// prove `archivedTemplateIDs` survive the full pipeline.
@MainActor
final class BackupSnapshotV5RoundTripTests: XCTestCase {

    private var sourceContainer: ModelContainer!
    private var destContainer: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        sourceContainer = try AppModelContainer.makeInMemory()
        destContainer = try AppModelContainer.makeInMemory()
        TemplateArchiveStore.clear()
    }

    override func tearDown() async throws {
        TemplateArchiveStore.clear()
        sourceContainer = nil
        destContainer = nil
        try await super.tearDown()
    }

    func test_v5RoundTrip_preservesArchivedIDsAcrossContainers() throws {
        let archivedA = UUID()
        let archivedB = UUID()
        TemplateArchiveStore.setArchived(true, for: archivedA)
        TemplateArchiveStore.setArchived(true, for: archivedB)

        let snapshot = try BackupService.export(from: sourceContainer.mainContext)
        let data = try BackupService.encode(snapshot)
        let decoded = try BackupService.decode(data)

        TemplateArchiveStore.clear()
        try BackupService.restore(decoded, into: destContainer.mainContext)
        XCTAssertEqual(TemplateArchiveStore.archivedIDs(), [archivedA, archivedB])

        let reexport = try BackupService.export(from: destContainer.mainContext)
        XCTAssertEqual(Set(reexport.archivedTemplateIDs ?? []), [archivedA, archivedB])
        XCTAssertGreaterThanOrEqual(reexport.version, 5)
    }

    func test_v5Encode_isStableAcrossEncodes() throws {
        TemplateArchiveStore.setArchived(true, for: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let snap = try BackupService.export(from: sourceContainer.mainContext)
        let firstPass = try BackupService.encode(snap)
        let secondPass = try BackupService.encode(snap)
        XCTAssertEqual(firstPass, secondPass)
    }
}
