import Foundation

/// Round-24 slice T3.18: stddev (variance) of bedtime minutes-from-midnight
/// across the trailing window. A high variance signals an inconsistent
/// sleep schedule, which the dashboard surfaces as a green/orange caption.
public enum SleepBedtimeVariance {

    public struct Summary: Equatable, Sendable {
        public let mean: Double
        public let stddev: Double
        public let sampleCount: Int
    }

    public static func summarize(
        bedtimeMinutes: [Int]
    ) -> Summary? {
        guard !bedtimeMinutes.isEmpty else { return nil }
        let values = bedtimeMinutes.map(Double.init)
        let mean = values.reduce(0, +) / Double(values.count)
        guard values.count > 1 else {
            return Summary(mean: mean, stddev: 0, sampleCount: values.count)
        }
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count - 1)
        return Summary(mean: mean, stddev: variance.squareRoot(), sampleCount: values.count)
    }

    /// Round-24 slice T3.18: green when stddev is < 30 min, orange when
    /// 30…60, red beyond. Pure verdict so the UI renders without owning
    /// a threshold.
    public enum Verdict: Equatable, Sendable {
        case consistent
        case driftSlight
        case driftSignificant
    }

    public static func verdict(stddevMinutes: Double) -> Verdict {
        switch stddevMinutes {
        case ..<30: return .consistent
        case ..<60: return .driftSlight
        default: return .driftSignificant
        }
    }
}
