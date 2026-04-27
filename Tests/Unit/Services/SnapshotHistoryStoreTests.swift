@testable import PersonalHygiene
import XCTest

@MainActor
final class SnapshotHistoryStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: "test.snapshot-history-\(UUID().uuidString)")!
    }

    private func makeSnapshot(commit: String, pending: Int) -> DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            buildVersion: "1.0",
            bundleVersion: "1",
            commitSHA: commit,
            processLaunchedAt: Date(),
            processUptimeSeconds: 0,
            pendingCount: pending,
            deliveredCount: 0,
            widgetReloadCount: 0,
            medicationObserverAvailable: false,
            medicationObserverIdentifiers: [],
            tripDocumentCount: 0,
            tripDocumentByteFootprint: nil,
            refreshTrace: [],
            pendingSummary: [],
            snapshotAt: Date(),
            localeIdentifier: "en_US",
            calendarIdentifier: "gregorian",
            timeZoneIdentifier: "UTC",
            pendingByCategory: nil
        )
    }

    func test_snapshots_emptyByDefault() {
        XCTAssertTrue(SnapshotHistoryStore.snapshots(defaults: defaults).isEmpty)
    }

    func test_record_storesNewestFirst() {
        SnapshotHistoryStore.record(makeSnapshot(commit: "a", pending: 1), in: defaults)
        SnapshotHistoryStore.record(makeSnapshot(commit: "b", pending: 2), in: defaults)
        let stored = SnapshotHistoryStore.snapshots(defaults: defaults)
        XCTAssertEqual(stored.first?.commitSHA, "b")
    }

    func test_record_capacityCapped() {
        for index in 0..<5 {
            SnapshotHistoryStore.record(makeSnapshot(commit: "c\(index)", pending: index), in: defaults)
        }
        let stored = SnapshotHistoryStore.snapshots(defaults: defaults)
        XCTAssertEqual(stored.count, SnapshotHistoryStore.capacity)
    }
}
