import Foundation

/// Round-25 slice T6.46: persists the watch user's preference for whether
/// completed blocks remain visible in the schedule list. When false, the
/// list filters out blocks already marked done.
public enum WatchShowCompletedToggleStore {

    public static let key = "watch.showCompleted.v1"

    public static func showCompleted(in defaults: UserDefaults = .standard) -> Bool {
        if defaults.object(forKey: key) == nil { return true }
        return defaults.bool(forKey: key)
    }

    public static func set(
        _ showCompleted: Bool,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(showCompleted, forKey: key)
    }
}
