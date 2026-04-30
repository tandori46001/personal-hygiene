@testable import PersonalHygiene
@preconcurrency import XCTest

final class NotificationAuthTimelineLogTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.auth-timeline-\(UUID().uuidString)")!
    }

    func test_record_dedupesIdenticalConsecutive() {
        NotificationAuthTimelineLog.record(statusRawValue: "authorized", in: defaults)
        NotificationAuthTimelineLog.record(statusRawValue: "authorized", in: defaults)
        XCTAssertEqual(NotificationAuthTimelineLog.entries(defaults: defaults).count, 1)
    }

    func test_record_logsChange() {
        NotificationAuthTimelineLog.record(statusRawValue: "authorized", in: defaults)
        NotificationAuthTimelineLog.record(statusRawValue: "denied", in: defaults)
        let entries = NotificationAuthTimelineLog.entries(defaults: defaults)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.first?.statusRawValue, "denied")
    }

    func test_capacityCapped() {
        for index in 0..<25 {
            NotificationAuthTimelineLog.record(
                statusRawValue: index.isMultiple(of: 2) ? "authorized" : "denied",
                in: defaults
            )
        }
        XCTAssertEqual(
            NotificationAuthTimelineLog.entries(defaults: defaults).count,
            NotificationAuthTimelineLog.capacity
        )
    }
}
