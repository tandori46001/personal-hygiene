import Foundation

/// Round-14 slice 31: pure helper for the trailing-7-days hydration average.
/// Caller passes the daily totals (already deduped to one entry per day);
/// returns the average ml/day, rounded to nearest 10ml for display.
public enum HydrationWeeklyAverage {

    public static func averageMilliliters(
        dailyTotals: [(date: Date, milliliters: Int)]
    ) -> Int {
        guard !dailyTotals.isEmpty else { return 0 }
        let sum = dailyTotals.reduce(0) { $0 + $1.milliliters }
        let avg = Double(sum) / Double(dailyTotals.count)
        return Int((avg / 10).rounded() * 10)
    }
}
