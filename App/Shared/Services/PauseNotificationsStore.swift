import Foundation

/// Round-12 slice 26: temporarily silences the scheduler. When `pausedUntil`
/// is in the future, `NotificationCoordinator.refreshForToday` short-circuits
/// the schedule pass. Stored as an absolute Date so it survives relaunches +
/// honors the original "pause for N hours" intent across app restarts.
public enum PauseNotificationsStore {

    public static let key = "notifications.pausedUntil"

    public static func pausedUntil(defaults: UserDefaults = .standard) -> Date? {
        let raw = defaults.double(forKey: key)
        guard raw > 0 else { return nil }
        return Date(timeIntervalSince1970: raw)
    }

    public static func isPaused(now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        guard let until = pausedUntil(defaults: defaults) else { return false }
        return until > now
    }

    public static func pause(
        until: Date,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(until.timeIntervalSince1970, forKey: key)
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    /// Convenience: pause for the given number of hours starting from `now`.
    public static func pauseForHours(
        _ hours: Double,
        now: Date = Date(),
        in defaults: UserDefaults = .standard
    ) {
        pause(until: now.addingTimeInterval(hours * 3_600), in: defaults)
    }
}
