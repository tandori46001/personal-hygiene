@testable import PersonalHygiene
import XCTest

/// Round-21 slice T1.5 — guards `MoodLogStore.exportCSV` shape: header line
/// present, ISO-8601 timestamps, newest-first ordering, no trailing newline.
/// The everything-bundle clipboard surface depends on this format being
/// stable across rounds.
final class MoodLogStoreCSVTests: XCTestCase {

    private let suite = "moodCSVTests-\(UUID().uuidString)"
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

    func test_exportCSV_emptyLog_emitsHeaderOnly() {
        let csv = MoodLogStore.exportCSV(defaults: defaults)
        XCTAssertEqual(csv, "recordedAt,mood")
        XCTAssertFalse(csv.hasSuffix("\n"), "no trailing newline")
    }

    func test_exportCSV_emitsHeaderThenNewestFirstRows() {
        let early = Date(timeIntervalSince1970: 1_700_000_000)
        let later = Date(timeIntervalSince1970: 1_700_086_400)
        MoodLogStore.record(.good, now: early, in: defaults)
        MoodLogStore.record(.bad, now: later, in: defaults)

        let csv = MoodLogStore.exportCSV(defaults: defaults)
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "recordedAt,mood")
        XCTAssertTrue(lines[1].hasSuffix(",bad"), "newest first")
        XCTAssertTrue(lines[2].hasSuffix(",good"))
    }

    func test_exportCSV_timestampIsISO8601() {
        let formatter = ISO8601DateFormatter()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        MoodLogStore.record(.okay, now: now, in: defaults)

        let csv = MoodLogStore.exportCSV(defaults: defaults)
        XCTAssertTrue(csv.contains(formatter.string(from: now)))
    }

    func test_exportCSV_capRespected_max30Rows() {
        for index in 0..<35 {
            MoodLogStore.record(
                .good,
                now: Date().addingTimeInterval(TimeInterval(index)),
                in: defaults
            )
        }
        let csv = MoodLogStore.exportCSV(defaults: defaults)
        let dataLines = csv.split(separator: "\n").dropFirst()
        XCTAssertEqual(dataLines.count, MoodLogStore.capacity)
    }
}
