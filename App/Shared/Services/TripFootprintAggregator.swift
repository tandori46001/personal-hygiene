import Foundation

/// Round-21 slice T3.17: aggregates per-trip carbon estimates into a single
/// footprint summary. Used by the Settings → "30-day footprint" section so
/// the user sees a quick rolling total without having to open each trip.
public enum TripFootprintAggregator {

    public struct Summary: Equatable, Sendable {
        public let totalKgCO2: Double
        public let tripCount: Int
        public let dominantMode: TripCarbonEstimate.TransportMode?
    }

    public struct TripContribution: Sendable {
        public let kgCO2: Double
        public let mode: TripCarbonEstimate.TransportMode
    }

    public static func summary(
        from contributions: [TripContribution]
    ) -> Summary {
        guard !contributions.isEmpty else {
            return Summary(totalKgCO2: 0, tripCount: 0, dominantMode: nil)
        }
        let total = contributions.reduce(0.0) { $0 + max(0, $1.kgCO2) }
        var counts: [TripCarbonEstimate.TransportMode: Int] = [:]
        for contribution in contributions {
            counts[contribution.mode, default: 0] += 1
        }
        let dominant = counts.max { $0.value < $1.value }?.key
        return Summary(totalKgCO2: total, tripCount: contributions.count, dominantMode: dominant)
    }
}
