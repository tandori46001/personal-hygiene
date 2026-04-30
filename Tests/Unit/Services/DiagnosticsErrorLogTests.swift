@preconcurrency import XCTest
@testable import PersonalHygiene

@MainActor
final class DiagnosticsErrorLogTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        DiagnosticsErrorLog.shared.clear()
    }

    override func tearDown() async throws {
        DiagnosticsErrorLog.shared.clear()
        try await super.tearDown()
    }

    func test_record_andRetrieveOrderNewestFirst() {
        DiagnosticsErrorLog.shared.record("first")
        DiagnosticsErrorLog.shared.record("second")
        DiagnosticsErrorLog.shared.record("third")

        let recent = DiagnosticsErrorLog.shared.recent(limit: 3)
        XCTAssertEqual(recent.count, 3)
        XCTAssertTrue(recent[0].contains("third"))
        XCTAssertTrue(recent[2].contains("first"))
    }

    func test_capacity_capsAtTwenty() {
        for idx in 0..<30 {
            DiagnosticsErrorLog.shared.record("error \(idx)")
        }
        XCTAssertEqual(DiagnosticsErrorLog.shared.recent(limit: 100).count, 20)
    }
}
