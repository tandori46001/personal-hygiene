import Foundation

/// Round-23 slice T3.17: pure helper that ranks marine forecast hours into
/// "best diving windows" based on wave height + wind speed proxies. The UI
/// surfaces the best contiguous block of hours matching the criteria.
public enum MarineDivingWindow {

    public struct HourlyConditions: Equatable, Sendable {
        public let hour: Date
        public let waveHeightMeters: Double
        public let windKnots: Double
    }

    public struct Window: Equatable, Sendable {
        public let start: Date
        public let end: Date
        public let hours: Int
    }

    /// Hours considered "diveable" use these defaults — values from
    /// recreational-dive guidance: ≤ 1 m wave height + ≤ 12 kt wind.
    public static let defaultMaxWaveHeight: Double = 1.0
    public static let defaultMaxWindKnots: Double = 12.0

    public static func bestWindow(
        in hourly: [HourlyConditions],
        maxWaveHeight: Double = defaultMaxWaveHeight,
        maxWindKnots: Double = defaultMaxWindKnots
    ) -> Window? {
        guard !hourly.isEmpty else { return nil }
        var bestRange: ClosedRange<Int>?
        var currentStart: Int?
        for (index, conditions) in hourly.enumerated() {
            let isDiveable = conditions.waveHeightMeters <= maxWaveHeight
                && conditions.windKnots <= maxWindKnots
            if isDiveable {
                if currentStart == nil { currentStart = index }
            } else if let start = currentStart {
                let range = start...(index - 1)
                if bestRange == nil || range.count > (bestRange?.count ?? 0) {
                    bestRange = range
                }
                currentStart = nil
            }
        }
        if let start = currentStart {
            let range = start...(hourly.count - 1)
            if bestRange == nil || range.count > (bestRange?.count ?? 0) {
                bestRange = range
            }
        }
        guard let final = bestRange else { return nil }
        let startHour = hourly[final.lowerBound].hour
        let endHour = hourly[final.upperBound].hour
        return Window(start: startHour, end: endHour, hours: final.count)
    }
}
