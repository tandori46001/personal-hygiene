import Foundation

/// Round-14 slice 42: more granular than `PauseNotificationsStore` (which is
/// time-bounded). Quiet hours suppress non-medication notifications every
/// day during a recurring `start...end` window. Times are stored as minutes
/// from midnight. Disabled by default.
public enum QuietHoursStore {

    public static let enabledKey = "notifications.quietHours.enabled"
    public static let startKey = "notifications.quietHours.startMinutes"
    public static let endKey = "notifications.quietHours.endMinutes"

    public static let defaultStartMinutes = 22 * 60      // 22:00
    public static let defaultEndMinutes = 7 * 60          // 07:00 (next day)

    public static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: enabledKey)
    }

    public static func setEnabled(_ value: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: enabledKey)
    }

    public static func startMinutes(defaults: UserDefaults = .standard) -> Int {
        let raw = defaults.integer(forKey: startKey)
        return raw == 0 ? defaultStartMinutes : raw
    }

    public static func endMinutes(defaults: UserDefaults = .standard) -> Int {
        let raw = defaults.integer(forKey: endKey)
        return raw == 0 ? defaultEndMinutes : raw
    }

    public static func setStartMinutes(_ value: Int, in defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: startKey)
    }

    public static func setEndMinutes(_ value: Int, in defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: endKey)
    }

    /// Returns `true` if `triggerMinutes` (minutes from midnight) falls
    /// inside the quiet window. Handles wrap-around (e.g. 22:00 → 07:00 next
    /// day) by checking either side of midnight.
    public static func contains(
        triggerMinutes: Int,
        startMinutes: Int? = nil,
        endMinutes: Int? = nil
    ) -> Bool {
        let start = startMinutes ?? Self.startMinutes()
        let end = endMinutes ?? Self.endMinutes()
        if start < end {
            return triggerMinutes >= start && triggerMinutes < end
        }
        // wrap-around
        return triggerMinutes >= start || triggerMinutes < end
    }
}
