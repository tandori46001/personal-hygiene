@testable import PersonalHygiene
@preconcurrency import XCTest

final class TripFootprintAggregatorTests: XCTestCase {

    func test_summary_isZeroForEmptyContributions() {
        let summary = TripFootprintAggregator.summary(from: [])
        XCTAssertEqual(summary.totalKgCO2, 0)
        XCTAssertEqual(summary.tripCount, 0)
        XCTAssertNil(summary.dominantMode)
    }

    func test_summary_sumsKgAndPicksMostCommonMode() {
        let contributions: [TripFootprintAggregator.TripContribution] = [
            .init(kgCO2: 100, mode: .flight),
            .init(kgCO2: 200, mode: .flight),
            .init(kgCO2: 50, mode: .ferry),
        ]
        let summary = TripFootprintAggregator.summary(from: contributions)
        XCTAssertEqual(summary.totalKgCO2, 350)
        XCTAssertEqual(summary.tripCount, 3)
        XCTAssertEqual(summary.dominantMode, .flight)
    }

    func test_summary_clampsNegativeValuesAtZero() {
        let summary = TripFootprintAggregator.summary(from: [
            .init(kgCO2: -10, mode: .car),
            .init(kgCO2: 100, mode: .car),
        ])
        XCTAssertEqual(summary.totalKgCO2, 100)
    }
}
