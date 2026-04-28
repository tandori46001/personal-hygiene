@testable import PersonalHygiene
import XCTest

final class PauseRemainingCaptionTests: XCTestCase {

    func test_caption_nilWhenNotPaused() {
        XCTAssertNil(PauseRemainingCaption.caption(pausedUntil: nil, now: Date()))
    }

    func test_caption_nilWhenPauseAlreadyExpired() {
        let now = Date()
        let earlier = now.addingTimeInterval(-60)
        XCTAssertNil(PauseRemainingCaption.caption(pausedUntil: earlier, now: now))
    }

    func test_caption_minutesOnlyWhenLessThanHour() {
        let now = Date()
        let later = now.addingTimeInterval(20 * 60)
        XCTAssertEqual(PauseRemainingCaption.caption(pausedUntil: later, now: now), "20m")
    }

    func test_caption_hoursAndMinutesWhenLong() {
        let now = Date()
        let later = now.addingTimeInterval(2 * 60 * 60 + 15 * 60)
        XCTAssertEqual(PauseRemainingCaption.caption(pausedUntil: later, now: now), "2h 15m")
    }
}
