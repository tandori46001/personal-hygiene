@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-24 slice T1.7 — guards that `CacheResetter.resetAll()` does NOT
/// touch the user's mood log. Mood lives in `.standard` defaults (not the
/// App Group); the resetter sweeps weather + currency caches only.
@MainActor
final class CacheResetterPreservesMoodTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MoodLogStore.clear()
    }

    override func tearDown() {
        MoodLogStore.clear()
        super.tearDown()
    }

    func test_resetAll_doesNotClearMoodLog() {
        MoodLogStore.record(.great, now: Date())
        XCTAssertEqual(MoodLogStore.entries().count, 1)

        CacheResetter.resetAll()

        XCTAssertEqual(MoodLogStore.entries().count, 1, "mood log must survive a cache reset")
    }

    func test_resetAll_doesNotZapMoodWeeklyGoal() {
        MoodWeeklyGoalStore.setGoal(4)
        CacheResetter.resetAll()
        XCTAssertEqual(MoodWeeklyGoalStore.goal(), 4)
    }
}
