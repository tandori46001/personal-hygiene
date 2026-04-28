@testable import PersonalHygiene
import XCTest

final class MedicationDoseHistoryCSVTests: XCTestCase {

    func test_render_emptyOnlyEmitsHeader() {
        let csv = MedicationDoseHistoryCSV.render([])
        XCTAssertEqual(csv, MedicationDoseHistoryCSV.header)
    }

    func test_render_escapesFieldsContainingCommas() {
        let entry = MedicationDoseHistory.Entry(
            blockID: UUID(),
            blockTitle: "Pastilla, mañana",
            conceptIdentifier: "concept-1",
            completedAt: Date(timeIntervalSince1970: 0)
        )
        let csv = MedicationDoseHistoryCSV.render([entry])
        XCTAssertTrue(csv.contains("\"Pastilla, mañana\""))
        XCTAssertTrue(csv.contains("concept-1"))
    }

    func test_render_handlesMissingConceptID() {
        let entry = MedicationDoseHistory.Entry(
            blockID: UUID(),
            blockTitle: "Take A",
            conceptIdentifier: nil,
            completedAt: Date(timeIntervalSince1970: 100)
        )
        let csv = MedicationDoseHistoryCSV.render([entry])
        XCTAssertTrue(csv.contains("Take A"))
    }
}
