@testable import PersonalHygiene
@preconcurrency import XCTest

final class MostRecentBackupStoreTests: XCTestCase {

    private let suite = "mostRecentBackupTests-\(UUID().uuidString)"
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

    func test_recordedURL_nilForFreshStore() {
        XCTAssertNil(MostRecentBackupStore.recordedURL(in: defaults))
        XCTAssertNil(MostRecentBackupStore.recordedName(in: defaults))
        XCTAssertNil(MostRecentBackupStore.recordedAt(in: defaults))
    }

    func test_record_persistsBookmarkAndMetadata() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-\(UUID().uuidString).json")
        try Data("{}".utf8).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        MostRecentBackupStore.record(url: tmp, in: defaults)

        XCTAssertEqual(MostRecentBackupStore.recordedName(in: defaults), tmp.lastPathComponent)
        XCTAssertNotNil(MostRecentBackupStore.recordedAt(in: defaults))
        XCTAssertNotNil(MostRecentBackupStore.recordedURL(in: defaults))
    }

    func test_clear_removesEveryKey() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-\(UUID().uuidString).json")
        try Data("{}".utf8).write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        MostRecentBackupStore.record(url: tmp, in: defaults)
        MostRecentBackupStore.clear(in: defaults)

        XCTAssertNil(MostRecentBackupStore.recordedURL(in: defaults))
        XCTAssertNil(MostRecentBackupStore.recordedName(in: defaults))
        XCTAssertNil(MostRecentBackupStore.recordedAt(in: defaults))
    }
}
