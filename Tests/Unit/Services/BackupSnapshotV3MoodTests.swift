@testable import PersonalHygiene
import SwiftData
import XCTest

/// Round-21 slice T1.3 — guards `BackupSnapshot` v3 mood payload through
/// export → encode → decode → restore. Round 20 added the `mood` field; this
/// proves it survives a full JSON round-trip and is replayed back into
/// `MoodLogStore` on restore.
@MainActor
final class BackupSnapshotV3MoodTests: XCTestCase {

    private var container: ModelContainer!
    private let suite = "backupV3MoodTests-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        container = try AppModelContainer.makeInMemory()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        MoodLogStore.clear()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        MoodLogStore.clear()
        container = nil
        try await super.tearDown()
    }

    func test_export_includesMoodPayload_whenLogHasEntries() throws {
        MoodLogStore.record(.great, now: Date(timeIntervalSince1970: 1_700_000_000))
        MoodLogStore.record(.bad, now: Date(timeIntervalSince1970: 1_700_086_400))

        let snapshot = try BackupService.export(from: container.mainContext)

        XCTAssertEqual(snapshot.mood?.count, 2)
        XCTAssertEqual(snapshot.version, 3)
    }

    func test_export_omitsMoodPayload_whenLogIsEmpty() throws {
        let snapshot = try BackupService.export(from: container.mainContext)
        XCTAssertNil(snapshot.mood, "empty log encodes as nil to keep v1/v2 wire shape")
    }

    func test_encodeDecode_preservesMoodEntriesNewestFirst() throws {
        MoodLogStore.record(.okay, now: Date(timeIntervalSince1970: 1_700_000_000))
        MoodLogStore.record(.great, now: Date(timeIntervalSince1970: 1_700_086_400))

        let original = try BackupService.export(from: container.mainContext)
        let decoded = try BackupService.decode(BackupService.encode(original))

        XCTAssertEqual(decoded.mood?.count, 2)
        XCTAssertEqual(decoded.mood?.first?.mood, MoodLogStore.Mood.great.rawValue,
                       "newest-first ordering preserved through encode/decode")
        XCTAssertEqual(decoded.mood?.last?.mood, MoodLogStore.Mood.okay.rawValue)
    }

    func test_restore_replaysMoodLogIntoStore() throws {
        MoodLogStore.record(.great, now: Date(timeIntervalSince1970: 1_700_000_000))
        let snapshot = try BackupService.export(from: container.mainContext)
        MoodLogStore.clear()
        XCTAssertTrue(MoodLogStore.entries().isEmpty)

        try BackupService.restore(snapshot, into: container.mainContext)

        let replayed = MoodLogStore.entries()
        XCTAssertEqual(replayed.count, 1)
        XCTAssertEqual(replayed.first?.mood, MoodLogStore.Mood.great.rawValue)
    }

    func test_restore_v2BackupWithoutMoodField_leavesExistingLogUntouched() throws {
        // Hand-crafted v2 JSON (pre-mood). Decoder accepts because mood is optional.
        let jsonString = """
        {
          "version": 2,
          "exportedAt": 1700000000.0,
          "templates": [],
          "completions": [],
          "hydration": [],
          "housekeeping": [],
          "trips": []
        }
        """
        MoodLogStore.record(.good, now: Date(timeIntervalSince1970: 1_700_000_000))
        let pre = MoodLogStore.entries()

        let decoded = try BackupService.decode(Data(jsonString.utf8))
        XCTAssertNil(decoded.mood)
        try BackupService.restore(decoded, into: container.mainContext)

        let post = MoodLogStore.entries()
        XCTAssertEqual(post.count, pre.count, "v2 restore must not wipe existing mood log")
    }
}
