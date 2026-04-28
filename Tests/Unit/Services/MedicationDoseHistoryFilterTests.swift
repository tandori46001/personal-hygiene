@testable import PersonalHygiene
import XCTest

final class MedicationDoseHistoryFilterTests: XCTestCase {

    private func entry(daysAgo: Int) -> MedicationDoseHistory.Entry {
        let date = Date().addingTimeInterval(-Double(daysAgo) * 86_400)
        return MedicationDoseHistory.Entry(
            blockID: UUID(),
            blockTitle: "Take A",
            conceptIdentifier: "concept-1",
            completedAt: date
        )
    }

    func test_filter_sevenDays_excludesOlder() {
        let entries = [entry(daysAgo: 1), entry(daysAgo: 6), entry(daysAgo: 8)]
        let result = MedicationDoseHistoryFilter.filter(entries, window: .sevenDays)
        XCTAssertEqual(result.count, 2)
    }

    func test_filter_thirtyDays_keepsThirtyDayHistory() {
        let entries = [entry(daysAgo: 5), entry(daysAgo: 25), entry(daysAgo: 31)]
        let result = MedicationDoseHistoryFilter.filter(entries, window: .thirtyDays)
        XCTAssertEqual(result.count, 2)
    }

    func test_filter_ninetyDays_includesEverythingInWindow() {
        let entries = [entry(daysAgo: 1), entry(daysAgo: 80), entry(daysAgo: 91)]
        let result = MedicationDoseHistoryFilter.filter(entries, window: .ninetyDays)
        XCTAssertEqual(result.count, 2)
    }

    func test_window_allCases_includesThree() {
        XCTAssertEqual(MedicationDoseHistoryFilter.Window.allCases.count, 3)
    }
}
