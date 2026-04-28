import Foundation

/// Round-23 slice T3.16: lightweight detector that flags when a currency
/// pair's rate has moved by more than `threshold` since the user's last
/// recorded conversion. Pure helper; UI side reads `LastConversionStore`
/// + the freshly-fetched rate and asks this helper for a verdict.
public enum CurrencyRateChangeDetector {

    public enum Direction: Equatable, Sendable {
        case up
        case down
        case stable
    }

    public struct Verdict: Equatable, Sendable {
        public let direction: Direction
        public let percentDelta: Double
    }

    public static let defaultThreshold: Double = 0.02  // 2%

    public static func evaluate(
        previousRate: Double,
        currentRate: Double,
        threshold: Double = defaultThreshold
    ) -> Verdict? {
        guard previousRate > 0, currentRate > 0 else { return nil }
        let delta = (currentRate - previousRate) / previousRate
        let absDelta = abs(delta)
        guard absDelta >= threshold else {
            return Verdict(direction: .stable, percentDelta: delta)
        }
        return Verdict(direction: delta > 0 ? .up : .down, percentDelta: delta)
    }
}
