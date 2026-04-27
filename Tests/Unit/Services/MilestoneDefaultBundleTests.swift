@testable import PersonalHygiene
import XCTest

final class MilestoneDefaultBundleTests: XCTestCase {

    func test_standardBundle_hasFourSeeds() {
        XCTAssertEqual(MilestoneDefaultBundle.standard.count, 4)
    }

    func test_standardBundle_daysBefore_descending() {
        let days = MilestoneDefaultBundle.standard.map(\.daysBefore)
        XCTAssertEqual(days, days.sorted(by: >))
    }

    func test_standardBundle_includes6m_3m_1m_1w() {
        let days = Set(MilestoneDefaultBundle.standard.map(\.daysBefore))
        XCTAssertTrue(days.contains(180))
        XCTAssertTrue(days.contains(90))
        XCTAssertTrue(days.contains(30))
        XCTAssertTrue(days.contains(7))
    }
}
