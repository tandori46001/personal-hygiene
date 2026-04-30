@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-22 slice T1.6 — guards a deterministic tie-break in
/// `TripFootprintAggregator.summary(...)`. Round 21 used `Dictionary.max`
/// which returns "any" entry on ties; the round-22 patch sorts modes by
/// their `rawValue` so the dominant mode is stable across calls.
final class TripFootprintTieBreakTests: XCTestCase {

    func test_summary_picksDeterministicWinnerOnTie() {
        let inputs: [TripFootprintAggregator.TripContribution] = [
            .init(kgCO2: 100, mode: .flight),
            .init(kgCO2: 100, mode: .car),
        ]
        // Two distinct modes each appearing once → tie. Run the summary
        // many times; result must be identical every time.
        var dominants: Set<TripCarbonEstimate.TransportMode?> = []
        for _ in 0..<20 {
            dominants.insert(TripFootprintAggregator.summary(from: inputs).dominantMode)
        }
        XCTAssertEqual(dominants.count, 1, "tie-break must be deterministic across calls")
    }

    func test_summary_winnerOnTie_isLowestRawValueAlphabetically() {
        let inputs: [TripFootprintAggregator.TripContribution] = [
            .init(kgCO2: 100, mode: .flight),
            .init(kgCO2: 100, mode: .car),
            .init(kgCO2: 100, mode: .ferry),
        ]
        let summary = TripFootprintAggregator.summary(from: inputs)
        // Sorted alphabetically: car < ferry < flight. Tie-break must pick
        // "car" so result is reproducible from any caller.
        XCTAssertEqual(summary.dominantMode, .car)
    }
}
