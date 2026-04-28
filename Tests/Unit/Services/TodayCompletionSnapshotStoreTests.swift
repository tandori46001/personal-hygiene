@testable import PersonalHygiene
import XCTest

final class TodayCompletionSnapshotStoreTests: XCTestCase {

    private let suite = "todaySnapshotTests-\(UUID().uuidString)"
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

    func test_writeAndRead_roundTripsValues() {
        let snap = TodayCompletionSnapshotStore.Snapshot(
            dayKey: "2026-04-28",
            done: 5,
            total: 10
        )
        TodayCompletionSnapshotStore.write(snap, in: defaults)
        let read = TodayCompletionSnapshotStore.read(in: defaults)
        XCTAssertEqual(read, snap)
    }

    func test_readForToday_nilForStaleSnapshot() {
        let snap = TodayCompletionSnapshotStore.Snapshot(
            dayKey: "1999-01-01",
            done: 1,
            total: 2
        )
        TodayCompletionSnapshotStore.write(snap, in: defaults)

        let cal = Calendar(identifier: .gregorian)
        let now = DateComponents(
            calendar: cal, year: 2026, month: 4, day: 28
        ).date!
        XCTAssertNil(TodayCompletionSnapshotStore.readForToday(
            now: now,
            calendar: cal,
            in: defaults
        ))
    }

    func test_clear_removesSnapshot() {
        TodayCompletionSnapshotStore.write(
            .init(dayKey: "2026-04-28", done: 0, total: 0),
            in: defaults
        )
        TodayCompletionSnapshotStore.clear(in: defaults)
        XCTAssertNil(TodayCompletionSnapshotStore.read(in: defaults))
    }
}
