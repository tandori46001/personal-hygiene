@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-25 slice T1.2: the "most recent" promise — a second `record(...)`
/// call must overwrite the first, and `recordedAt` must reflect the
/// later timestamp.
final class MostRecentBackupStoreOrderTests: XCTestCase {

    private let suite = "mostRecentOrder-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_record_secondCallWinsOverFirst() throws {
        let dir = FileManager.default.temporaryDirectory
        let urlA = dir.appendingPathComponent("backup-A-\(UUID().uuidString).json")
        let urlB = dir.appendingPathComponent("backup-B-\(UUID().uuidString).json")
        try Data("{}".utf8).write(to: urlA)
        try Data("{}".utf8).write(to: urlB)
        defer {
            try? FileManager.default.removeItem(at: urlA)
            try? FileManager.default.removeItem(at: urlB)
        }

        MostRecentBackupStore.record(url: urlA, in: defaults)
        let firstRecordedAt = MostRecentBackupStore.recordedAt(in: defaults)
        Thread.sleep(forTimeInterval: 0.01)
        MostRecentBackupStore.record(url: urlB, in: defaults)

        XCTAssertEqual(MostRecentBackupStore.recordedName(in: defaults), urlB.lastPathComponent)
        let secondRecordedAt = MostRecentBackupStore.recordedAt(in: defaults)
        XCTAssertNotNil(firstRecordedAt)
        XCTAssertNotNil(secondRecordedAt)
        XCTAssertGreaterThan(secondRecordedAt!, firstRecordedAt!)
    }
}
