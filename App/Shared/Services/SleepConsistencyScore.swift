import Foundation

/// Round-25 slice T3.17: combined "consistency score" mixing bedtime
/// variance (lower = better) with duration adherence to a target. Returns
/// a 0…100 integer suitable for a dashboard chip. Pure helper — no I/O.
public enum SleepConsistencyScore {

    public static let targetMinutes = 480

    public struct Inputs: Equatable, Sendable {
        public let bedtimeMinutesPerNight: [Int]
        public let durationMinutesPerNight: [Int]

        public init(bedtimeMinutesPerNight: [Int], durationMinutesPerNight: [Int]) {
            self.bedtimeMinutesPerNight = bedtimeMinutesPerNight
            self.durationMinutesPerNight = durationMinutesPerNight
        }
    }

    public static func score(_ inputs: Inputs) -> Int? {
        guard let variance = SleepBedtimeVariance.summarize(
            bedtimeMinutes: inputs.bedtimeMinutesPerNight
        ) else { return nil }
        guard !inputs.durationMinutesPerNight.isEmpty else { return nil }

        // Bedtime sub-score: 0 stddev → 100, 90+ stddev → 0. Linear in between.
        let varianceComponent = max(0, min(100, 100 - Int(variance.stddev * (100.0 / 90.0))))

        // Duration sub-score: average duration vs `targetMinutes`. Within
        // ±30 min → 100; ±60 min → 70; further → 30.
        let avgDuration = Double(inputs.durationMinutesPerNight.reduce(0, +))
            / Double(inputs.durationMinutesPerNight.count)
        let durationDelta = abs(avgDuration - Double(targetMinutes))
        let durationComponent: Int
        switch durationDelta {
        case ..<30: durationComponent = 100
        case ..<60: durationComponent = 70
        default: durationComponent = 30
        }

        // 60/40 weight in favor of consistency (bedtime variance is the
        // dominant lever the user can act on).
        return Int(0.6 * Double(varianceComponent) + 0.4 * Double(durationComponent))
    }

    public enum Tier: Equatable, Sendable {
        case excellent
        case good
        case poor
    }

    public static func tier(for score: Int) -> Tier {
        switch score {
        case 80...: return .excellent
        case 50...: return .good
        default: return .poor
        }
    }
}
