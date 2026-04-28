@testable import PersonalHygiene
import XCTest

final class SleepConsistencyScoreTests: XCTestCase {

    func test_score_nilWhenInputsEmpty() {
        XCTAssertNil(SleepConsistencyScore.score(.init(
            bedtimeMinutesPerNight: [],
            durationMinutesPerNight: []
        )))
    }

    func test_score_excellentForConsistentTargetSleeper() {
        let inputs = SleepConsistencyScore.Inputs(
            bedtimeMinutesPerNight: [1380, 1380, 1380, 1380, 1380],
            durationMinutesPerNight: [480, 480, 480, 480, 480]
        )
        let score = SleepConsistencyScore.score(inputs)!
        XCTAssertGreaterThanOrEqual(score, 80)
        XCTAssertEqual(SleepConsistencyScore.tier(for: score), .excellent)
    }

    func test_score_poorForChaoticSchedule() {
        let inputs = SleepConsistencyScore.Inputs(
            bedtimeMinutesPerNight: [1320, 60, 1380, 120, 1320],
            durationMinutesPerNight: [240, 600, 200, 660, 240]
        )
        let score = SleepConsistencyScore.score(inputs)!
        XCTAssertLessThanOrEqual(score, 50)
    }

    func test_tier_thresholds() {
        XCTAssertEqual(SleepConsistencyScore.tier(for: 100), .excellent)
        XCTAssertEqual(SleepConsistencyScore.tier(for: 80), .excellent)
        XCTAssertEqual(SleepConsistencyScore.tier(for: 79), .good)
        XCTAssertEqual(SleepConsistencyScore.tier(for: 50), .good)
        XCTAssertEqual(SleepConsistencyScore.tier(for: 49), .poor)
        XCTAssertEqual(SleepConsistencyScore.tier(for: 0), .poor)
    }
}
