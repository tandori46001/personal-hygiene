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

    /// Number of consecutive days (ending on the calendar day of `now`) where
    /// total hydration met or exceeded `goal.dailyMilliliters`. The current
    /// day counts only when its total has already crossed the goal.
    public static func currentStreakDays(
        on now: Date,
        logs: [HydrationLog],
        goal: HydrationGoal,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        guard goal.dailyMilliliters > 0 else { return 0 }
        let totalsByDay = Self.totalsByDay(logs: logs, calendar: calendar)

        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        while let total = totalsByDay[cursor], total >= goal.dailyMilliliters {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest run of consecutive goal-meeting days observed anywhere in `logs`
    /// up to and including `now`. Useful for "best streak" badges that survive
    /// a missed day. Always >= `currentStreakDays(...)`.
    public static func bestStreakDays(
        on now: Date,
        logs: [HydrationLog],
        goal: HydrationGoal,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        guard goal.dailyMilliliters > 0 else { return 0 }
        let totalsByDay = Self.totalsByDay(logs: logs, calendar: calendar)
        let metDays = totalsByDay.filter { $0.value >= goal.dailyMilliliters }.keys.sorted()
        guard !metDays.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: now)
        var best = 0
        var run = 0
        var previous: Date?
        for day in metDays where day <= today {
            if let prev = previous,
               let next = calendar.date(byAdding: .day, value: 1, to: prev),
               next == day {
                run += 1
            } else {
                run = 1
            }
            previous = day
            best = max(best, run)
        }
        return best
    }

    private static func totalsByDay(logs: [HydrationLog], calendar: Calendar) -> [Date: Int] {
        Dictionary(grouping: logs) { log -> Date in
            calendar.startOfDay(for: log.drankAt)
        }.mapValues { $0.reduce(0) { $0 + max(0, $1.milliliters) } }
    }
}
