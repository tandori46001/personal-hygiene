import Foundation

/// Round-13 slice 30: counts consecutive days a given housekeeping room had
/// at least one task completed. Pure helper — no persistence. Caller passes
/// the completion log (each entry being the day a task was completed in that
/// room) and gets back the count.
public enum HousekeepingStreakCounter {

    /// Returns the number of consecutive days ending on `now` (inclusive)
    /// where the room had at least one completion. Today only counts when
    /// it's already in `completionDays`.
    public static func currentStreak(
        room: String,
        completionDays: Set<String>,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        _ = room
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        while completionDays.contains(Self.dayKey(cursor, calendar: calendar)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Returns the longest run anywhere in `completionDays` up to and
    /// including `now`. Always >= `currentStreak`.
    public static func bestStreak(
        room: String,
        completionDays: Set<String>,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        _ = room
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
