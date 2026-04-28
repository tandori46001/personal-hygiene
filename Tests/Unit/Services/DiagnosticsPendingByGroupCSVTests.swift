@testable import PersonalHygiene
import XCTest

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
}
