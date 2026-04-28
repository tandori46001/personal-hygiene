import Foundation

/// Round-24 slice T6.31 + T6.32: shared helper that turns a `(done, total)`
/// pair into a 0…100 percentage string + a clamp. Used by the Today watch
/// glance + the rectangular complication line-3.
public enum TodayCompletionPercent {

    public static func percent(done: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let raw = Double(done) / Double(total)
        return Int((raw * 100).rounded())
    }

    public static func formatted(done: Int, total: Int) -> String {
        "\(percent(done: done, total: total))%"
    }
}
