import Foundation

/// Round-21 slice T6.30: deferred polish from round 13 — when a housekeeping
/// task completes a streak threshold (e.g. 7 consecutive days), surface a
/// short auto-snooze suggestion so the user isn't pinged the very next day.
/// Pure helper; the UI decides whether to honour the suggestion.
public enum HousekeepingStreakAutoSnooze {

    /// Streak length at which the auto-snooze kicks in. 7 days mirrors the
    /// existing `HousekeepingStreakCounter` weekly cadence.
    public static let triggerThresholdDays = 7
    public static let snoozeDurationDays = 3

    public static func suggestedSnoozeDays(currentStreak: Int) -> Int {
        guard currentStreak >= triggerThresholdDays else { return 0 }
        // Reward longer streaks with proportionally longer breathing room,
        // capped at one week so we never silently disable the task.
        let scale = currentStreak / triggerThresholdDays
        return min(7, snoozeDurationDays * scale)
    }

    public static func snoozedUntil(
        currentStreak: Int,
        from now: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        let days = suggestedSnoozeDays(currentStreak: currentStreak)
        guard days > 0 else { return nil }
        return calendar.date(byAdding: .day, value: days, to: now)
    }
}
