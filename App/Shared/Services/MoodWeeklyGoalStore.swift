import Foundation

/// Round-21 slice T2.11: persists an optional weekly "good days" target so
/// the Today caption + Settings disclosure can render a `3 / 5` style ratio
/// instead of just the raw count. Target of zero means "no goal set" and the
/// caption falls back to the bare count behaviour.
public enum MoodWeeklyGoalStore {

    public static let key = "today.moodWeeklyGoal"
    public static let allowedRange = 0...7

    public static func goal(in defaults: UserDefaults = .standard) -> Int {
        let raw = defaults.integer(forKey: key)
        return allowedRange.contains(raw) ? raw : 0
    }

    public static func setGoal(_ value: Int, in defaults: UserDefaults = .standard) {
        let clamped = max(allowedRange.lowerBound, min(allowedRange.upperBound, value))
        defaults.set(clamped, forKey: key)
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    /// True when the user has set a non-zero target.
    public static func isActive(in defaults: UserDefaults = .standard) -> Bool {
        goal(in: defaults) > 0
    }
}
