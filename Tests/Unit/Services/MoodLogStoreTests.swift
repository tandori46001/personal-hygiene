@testable import PersonalHygiene
import XCTest

/// Round-20 slice T1.6 — guards `MoodLogStore.record` cap behavior + the
/// `todayEntry(now:calendar:)` filter so the Today UI's highlight stays
/// pinned to the most-recent same-day record.
final class MoodLogStoreTests: XCTestCase {

    private let suite = "moodLogTests-\(UUID().uuidString)"
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

    func test_record_capsAtCapacity_keepingNewestFirst() {
        for index in 0..<35 {
            MoodLogStore.record(
                .good,
                now: Date().addingTimeInterval(TimeInterval(index)),
                in: defaults
            )
        }
        let entries = MoodLogStore.entries(defaults: defaults)
        XCTAssertEqual(entries.count, MoodLogStore.capacity)
        XCTAssertEqual(entries.count, 30)
        let timestamps = entries.map(\.recordedAt.timeIntervalSince1970)
        XCTAssertEqual(timestamps, timestamps.sorted(by: >), "newest-first ordering preserved")
    }

    func test_todayEntry_returnsOnlyMostRecentSameDay() {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        MoodLogStore.record(.bad, now: yesterday, in: defaults)
        MoodLogStore.record(.okay, now: today.addingTimeInterval(60), in: defaults)
        MoodLogStore.record(.great, now: today.addingTimeInterval(3600), in: defaults)

        let entry = MoodLogStore.todayEntry(now: today.addingTimeInterval(7200), calendar: cal, defaults: defaults)
        XCTAssertEqual(entry?.mood, MoodLogStore.Mood.great.rawValue)
    }

    func test_todayEntry_returnsNilWhenNoSameDayRecord() {
        let cal = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = cal.date(byAdding: .day, value: -1, to: now) ?? now
        MoodLogStore.record(.bad, now: yesterday, in: defaults)

        XCTAssertNil(MoodLogStore.todayEntry(now: now, calendar: cal, defaults: defaults))
    }

    func test_clear_removesAllEntries() {
        MoodLogStore.record(.good, in: defaults)
        XCTAssertFalse(MoodLogStore.entries(defaults: defaults).isEmpty)
        MoodLogStore.clear(in: defaults)
        XCTAssertTrue(MoodLogStore.entries(defaults: defaults).isEmpty)
    }
}
