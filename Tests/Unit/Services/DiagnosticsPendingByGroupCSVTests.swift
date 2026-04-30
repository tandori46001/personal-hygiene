@testable import PersonalHygiene
@preconcurrency import XCTest

@MainActor
final class DiagnosticsPendingByGroupCSVTests: XCTestCase {

    func test_emptyPendingDetails_returnsHeaderOnly() {
        let csv = DiagnosticsView.pendingByGroupCSV(pendingDetails: [])
        XCTAssertEqual(csv, "category,identifier,triggerDate")
    }

    func test_groupsRoutineAndMedFollowupSeparately() {
        let routine = DiagnosticsSnapshot.PendingNotificationSummary(
            identifier: "\(NotificationFactory.identifierPrefix)foo",
            triggerDate: nil
        )
        let medFollowup = DiagnosticsSnapshot.PendingNotificationSummary(
            identifier: "\(MedicationFollowUpFactory.identifierPrefix)bar",
            triggerDate: nil
        )
        let csv = DiagnosticsView.pendingByGroupCSV(pendingDetails: [routine, medFollowup])
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines.contains { $0.hasPrefix("routine,") })
        XCTAssertTrue(lines.contains { $0.hasPrefix("medicationFollowUp,") })
    }

    /// Round-20 slice T1.5: header-only CSV must end without a trailing newline
    /// — both consumers (Numbers/Excel) treat a trailing blank as a phantom
    /// empty row. This guards against a regression where someone might wrap
    /// the joined string with `+ "\n"` for "consistency" with files-on-disk.
    func test_emptyCSV_hasNoTrailingNewline() {
        let csv = DiagnosticsView.pendingByGroupCSV(pendingDetails: [])
        XCTAssertFalse(csv.hasSuffix("\n"), "header-only CSV should not end with a newline")
        XCTAssertEqual(csv.split(separator: "\n").count, 1)
    }

    /// Identifiers containing commas must be sanitized into semicolons so the
    /// CSV doesn't get a phantom column. Round-20 slice T1.5 regression guard.
    func test_identifiersWithCommas_areSanitized() {
        let entry = DiagnosticsSnapshot.PendingNotificationSummary(
            identifier: "personal-hygiene.block.UUID,with,comma.dayKey",
            triggerDate: nil
        )
        let csv = DiagnosticsView.pendingByGroupCSV(pendingDetails: [entry])
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count >= 2 else { XCTFail("expected ≥2 lines"); return }
        // Each row must split into exactly 3 columns.
        XCTAssertEqual(lines[1].split(separator: ",", omittingEmptySubsequences: false).count, 3)
        XCTAssertTrue(String(lines[1]).contains(";with;comma"))
    }
}
