@testable import PersonalHygiene
import XCTest

final class SleepBedtimeVarianceTests: XCTestCase {

    func test_summarize_nilForEmpty() {
        XCTAssertNil(SleepBedtimeVariance.summarize(bedtimeMinutes: []))
    }

    func test_summarize_zeroVarianceForIdenticalSamples() {
        let summary = SleepBedtimeVariance.summarize(bedtimeMinutes: [600, 600, 600])
        XCTAssertEqual(summary?.stddev, 0)
        XCTAssertEqual(summary?.mean, 600)
    }

    func test_verdict_thresholds() {
        XCTAssertEqual(SleepBedtimeVariance.verdict(stddevMinutes: 0), .consistent)
        XCTAssertEqual(SleepBedtimeVariance.verdict(stddevMinutes: 29), .consistent)
        XCTAssertEqual(SleepBedtimeVariance.verdict(stddevMinutes: 45), .driftSlight)
        XCTAssertEqual(SleepBedtimeVariance.verdict(stddevMinutes: 90), .driftSignificant)
    }

    func test_summarize_singleSampleHasZeroStddev() {
        let summary = SleepBedtimeVariance.summarize(bedtimeMinutes: [600])
        XCTAssertEqual(summary?.stddev, 0)
        XCTAssertEqual(summary?.sampleCount, 1)
    }
}
