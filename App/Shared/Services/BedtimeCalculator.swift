import Foundation

/// Compute bedtime from wake-up time + sleep target. Pure, fully testable.
public enum BedtimeCalculator {

    public static let defaultSleepTargetMinutes: Int = 7 * 60 + 45  // 7h45m

    /// Given a wake-up time expressed as minutes-from-midnight, return the
    /// bedtime (also minutes-from-midnight) that yields exactly `durationMinutes`
    /// of sleep. Wraps backwards across midnight.
    public static func bedtimeMinutes(
        forWakeUp wakeUpMinutes: Int,
        sleepTarget durationMinutes: Int = defaultSleepTargetMinutes
    ) -> Int {
        let dayMinutes = 24 * 60
        let raw = wakeUpMinutes - durationMinutes
        return ((raw % dayMinutes) + dayMinutes) % dayMinutes
    }

    /// Compare actual sleep against the user's target.
    public static func deficit(
        actualMinutes: Int,
        targetMinutes: Int = defaultSleepTargetMinutes
    ) -> Int {
        targetMinutes - actualMinutes
    }
}
