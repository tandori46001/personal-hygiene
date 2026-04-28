import Foundation

/// Round-25 slice T6.43: tracks whether the "goal reached today" haptic
/// has already played for the current day-bucket so the watch glance
/// doesn't buzz repeatedly when the user logs additional sips after
/// already hitting the daily target.
public enum HydrationGoalReachedHaptic {

    public static let key = "hydration.goalHapticPlayedDay"

    public static func shouldPlay(
        currentTotalMl: Int,
        goalMl: Int,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = .standard
    ) -> Bool {
        guard goalMl > 0, currentTotalMl >= goalMl else { return false }
        let dayKey = Self.dayKey(now: now, calendar: calendar)
        let stored = defaults.string(forKey: key)
        return stored != dayKey
    }

    public static func recordPlayed(
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(Self.dayKey(now: now, calendar: calendar), forKey: key)
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    static func dayKey(now: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        return String(
            format: "%04d-%02d-%02d",
            comps.year ?? 0, comps.month ?? 0, comps.day ?? 0
        )
    }
}
