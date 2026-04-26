import Foundation

/// Pure arithmetic helpers for the hydration dashboard. No persistence —
/// callers fetch logs and feed them in.
public enum HydrationCompliance {

    /// Total millilitres logged on the calendar day of `now`.
    public static func totalMilliliters(
        on now: Date,
        logs: [HydrationLog],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let day = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: day) else {
            return 0
        }
        return
            logs
            .filter { $0.drankAt >= day && $0.drankAt < endOfDay }
            .reduce(0) { $0 + max(0, $1.milliliters) }
    }

    /// Progress (0...1) toward `goal` on the calendar day of `now`. Capped at 1.
    public static func progress(
        on now: Date,
        logs: [HydrationLog],
        goal: HydrationGoal,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double {
        guard goal.dailyMilliliters > 0 else { return 1 }
        let total = totalMilliliters(on: now, logs: logs, calendar: calendar)
        return min(1.0, Double(total) / Double(goal.dailyMilliliters))
    }
}
