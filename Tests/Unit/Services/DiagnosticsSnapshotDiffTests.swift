@testable import PersonalHygiene
@preconcurrency import XCTest

final class DiagnosticsSnapshotDiffTests: XCTestCase {

    private func makeSnapshot(
        commit: String,
        pending: Int,
        delivered: Int,
        widgetReloads: Int,
        observerIDs: [String] = [],
        tripDocCount: Int = 0
    ) -> DiagnosticsSnapshot {
        DiagnosticsSnapshot(
            buildVersion: "1.0",
            bundleVersion: "1",
            commitSHA: commit,
            processLaunchedAt: Date(),
            processUptimeSeconds: 30,
            pendingCount: pending,
            deliveredCount: delivered,
            widgetReloadCount: widgetReloads,
            medicationObserverAvailable: false,
            medicationObserverIdentifiers: observerIDs,
            tripDocumentCount: tripDocCount,
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

    func test_diff_scalarDeltas() {
        let older = makeSnapshot(commit: "abc", pending: 5, delivered: 1, widgetReloads: 0)
        let newer = makeSnapshot(commit: "abc", pending: 8, delivered: 3, widgetReloads: 2)
        let diff = DiagnosticsSnapshot.diff(from: older, to: newer)
        XCTAssertEqual(diff.pendingDelta, 3)
        XCTAssertEqual(diff.deliveredDelta, 2)
        XCTAssertEqual(diff.widgetReloadDelta, 2)
        XCTAssertFalse(diff.buildChanged)
    }

    func test_diff_buildChanged() {
        let older = makeSnapshot(commit: "abc", pending: 0, delivered: 0, widgetReloads: 0)
        let newer = makeSnapshot(commit: "def", pending: 0, delivered: 0, widgetReloads: 0)
        XCTAssertTrue(DiagnosticsSnapshot.diff(from: older, to: newer).buildChanged)
    }

    func test_diff_observerAdditionsAndRemovals() {
        let older = makeSnapshot(
            commit: "abc",
            pending: 0,
            delivered: 0,
            widgetReloads: 0,
            observerIDs: ["A", "B"]
        )
        let newer = makeSnapshot(
            commit: "abc",
            pending: 0,
            delivered: 0,
            widgetReloads: 0,
            observerIDs: ["B", "C"]
        )
        let diff = DiagnosticsSnapshot.diff(from: older, to: newer)
        XCTAssertEqual(diff.observerIdentifierAdditions, ["C"])
        XCTAssertEqual(diff.observerIdentifierRemovals, ["A"])
    }
}
