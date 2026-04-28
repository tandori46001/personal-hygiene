import Foundation

/// Round-24 slice T3.17: best/current consecutive-day adherence streak for
/// medication doses. Pure helper — caller passes the day-keyed
/// "took at least one dose" set.
public enum MedicationStreakCounter {

    public static func currentStreak(
        completionDays: Set<String>,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        while completionDays.contains(Self.dayKey(cursor, calendar: calendar)) {
            streak += 1
            guard let prior = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prior
        }
        return streak
    }

    public static func bestStreak(
        completionDays: Set<String>,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let today = calendar.startOfDay(for: now)
        let sortedDays = completionDays.compactMap { Self.dateFromKey($0, calendar: calendar) }
            .filter { $0 <= today }
            .sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var best = 0
        var run = 0
        var previous: Date?
        for day in sortedDays {
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

    public static func dayKey(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            comps.year ?? 0,
            comps.month ?? 0,
            comps.day ?? 0
        )
    }

    public static func dateFromKey(
        _ key: String,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps)
    }
}
