import Foundation

/// Round-22 slice T2.10: lightweight per-room completion log so
/// `HousekeepingStreakCounter` (round 13) finally has the day-key set it
/// always required. Entries are appended whenever a task in that room is
/// marked done; never auto-pruned (the streak counter only consults the
/// trailing window anyway).
public enum HousekeepingCompletionLog {

    public static let key = "housekeeping.completionLog.v1"

    public static func record(
        room: String,
        on date: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = .standard
    ) {
        let dayKey = HousekeepingStreakCounter.dayKey(date, calendar: calendar)
        var stored = readMap(in: defaults)
        var roomDays = Set(stored[room] ?? [])
        roomDays.insert(dayKey)
        stored[room] = Array(roomDays)
        defaults.set(stored, forKey: key)
    }

    public static func days(
        room: String,
        in defaults: UserDefaults = .standard
    ) -> Set<String> {
        let stored = readMap(in: defaults)
        return Set(stored[room] ?? [])
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    /// Round-24 slice T2.9: every room (string key) currently tracked.
    /// Used by the Diagnostics dump section to enumerate streaks.
    public static func allRooms(in defaults: UserDefaults = .standard) -> [String] {
        readMap(in: defaults).keys.sorted()
    }

    /// Streak-aware suggestion convenience: combines the round-13 streak
    /// counter with the round-21 auto-snooze threshold so the banner can
    /// render in one call.
    public static func suggestedSnoozeDays(
        room: String,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = .standard
    ) -> (currentStreak: Int, snoozeDays: Int) {
        let streak = HousekeepingStreakCounter.currentStreak(
            room: room,
            completionDays: days(room: room, in: defaults),
            now: now,
            calendar: calendar
        )
        return (streak, HousekeepingStreakAutoSnooze.suggestedSnoozeDays(currentStreak: streak))
    }

    private static func readMap(in defaults: UserDefaults) -> [String: [String]] {
        defaults.dictionary(forKey: key) as? [String: [String]] ?? [:]
    }
}
