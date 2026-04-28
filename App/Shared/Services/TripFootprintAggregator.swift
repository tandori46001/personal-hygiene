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
        // Round-22 slice T1.6: tie-break by `rawValue` so callers get a
        // deterministic dominant mode when multiple modes are tied on count.
        let dominant = counts.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            // For equal counts, the alphabetically smaller rawValue wins —
            // `max` returns the *largest*, so invert here.
            return lhs.key.rawValue > rhs.key.rawValue
        }?.key
        return Summary(totalKgCO2: total, tripCount: contributions.count, dominantMode: dominant)
    }
}
