@testable import PersonalHygiene
@preconcurrency import XCTest

final class NetworkActivityCounterTests: XCTestCase {

    private var counter: NetworkActivityCounter!

    override func setUp() {
        super.setUp()
        counter = NetworkActivityCounter()
    }

    func test_record_incrementsCount() {
        counter.record(.frankfurter)
        counter.record(.frankfurter)
        counter.record(.openMeteo)
        XCTAssertEqual(counter.count(for: .frankfurter), 2)
        XCTAssertEqual(counter.count(for: .openMeteo), 1)
        XCTAssertEqual(counter.count(for: .advisory), 0)
    }

    func test_lastFired_tracksTimestamp() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        counter.record(.frankfurter, at: date)
        XCTAssertEqual(counter.lastFired(for: .frankfurter)?.timeIntervalSince1970, 1_700_000_000)
    }

    func test_reset_clearsAll() {
        counter.record(.frankfurter)
        counter.record(.openMeteo)
        counter.recordOutcome(.frankfurter, outcome: .rateLimited)
        counter.recordOutcome(.openMeteo, outcome: .serverError)
        counter.reset()
        XCTAssertEqual(counter.count(for: .frankfurter), 0)
        XCTAssertEqual(counter.count(for: .openMeteo), 0)
        XCTAssertEqual(counter.count(for: .frankfurter, outcome: .rateLimited), 0)
        XCTAssertEqual(counter.count(for: .openMeteo, outcome: .serverError), 0)
        XCTAssertFalse(counter.hasFailureOutcome(for: .frankfurter))
        XCTAssertFalse(counter.hasFailureOutcome(for: .openMeteo))
    }

    // MARK: - Round 31 (O02/O03): outcome tracking

    func test_recordOutcome_partitionsBySource() {
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.frankfurter, outcome: .rateLimited)
        counter.recordOutcome(.openMeteo, outcome: .serverError)

        XCTAssertEqual(counter.count(for: .frankfurter, outcome: .success), 2)
        XCTAssertEqual(counter.count(for: .frankfurter, outcome: .rateLimited), 1)
        XCTAssertEqual(counter.count(for: .openMeteo, outcome: .serverError), 1)
        XCTAssertEqual(counter.count(for: .openMeteo, outcome: .success), 0)
    }

    func test_recordOutcome_doesNotAffectAttemptCounts() {
        // Attempts and outcomes are tracked independently — record() counts
        // attempts (called pre-request), recordOutcome() counts results
        // (called post-response). Both must coexist without cross-talk.
        counter.record(.frankfurter)
        counter.record(.frankfurter)
        counter.recordOutcome(.frankfurter, outcome: .rateLimited)

        XCTAssertEqual(counter.count(for: .frankfurter), 2)
        XCTAssertEqual(counter.count(for: .frankfurter, outcome: .rateLimited), 1)
    }

    func test_outcomes_returnsAllForSource() {
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.frankfurter, outcome: .decodingError)
        let outcomes = counter.outcomes(for: .frankfurter)
        XCTAssertEqual(outcomes[.success], 2)
        XCTAssertEqual(outcomes[.decodingError], 1)
        XCTAssertNil(outcomes[.rateLimited])
    }

    func test_hasFailureOutcome_falseWhenAllSuccess() {
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.frankfurter, outcome: .success)
        XCTAssertFalse(counter.hasFailureOutcome(for: .frankfurter))
    }

    func test_hasFailureOutcome_trueWhenAnyNonSuccess() {
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.frankfurter, outcome: .rateLimited)
        XCTAssertTrue(counter.hasFailureOutcome(for: .frankfurter))
    }

    func test_hasFailureOutcome_falseWhenNothingRecorded() {
        XCTAssertFalse(counter.hasFailureOutcome(for: .openMeteo))
    }

    func test_lastOutcome_tracksTimestampPerOutcome() {
        let t1 = Date(timeIntervalSince1970: 1_700_000_000)
        let t2 = Date(timeIntervalSince1970: 1_700_000_500)
        counter.recordOutcome(.openMeteo, outcome: .rateLimited, at: t1)
        counter.recordOutcome(.openMeteo, outcome: .success, at: t2)
        XCTAssertEqual(
            counter.lastOutcome(for: .openMeteo, outcome: .rateLimited)?.timeIntervalSince1970,
            1_700_000_000
        )
        XCTAssertEqual(
            counter.lastOutcome(for: .openMeteo, outcome: .success)?.timeIntervalSince1970,
            1_700_000_500
        )
        XCTAssertNil(counter.lastOutcome(for: .openMeteo, outcome: .serverError))
    }

    func test_outcomeTotals_returnsSnapshot() {
        counter.recordOutcome(.frankfurter, outcome: .success)
        counter.recordOutcome(.openMeteo, outcome: .rateLimited)
        let totals = counter.outcomeTotals
        XCTAssertEqual(totals[.frankfurter]?[.success], 1)
        XCTAssertEqual(totals[.openMeteo]?[.rateLimited], 1)
    }

    func test_outcomeEnum_caseIterable() {
        // Guard: the Diagnostics surface iterates allCases when rendering
        // the breakdown row. Adding a case here without updating the surface
        // would silently miss entries — verify the enum is CaseIterable.
        XCTAssertEqual(NetworkActivityCounter.Outcome.allCases.count, 5)
    }
}
