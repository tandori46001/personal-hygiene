import Foundation

/// Round-21 slice T5.25: cross-process App-Group store that holds today's
/// hydration milliliter total (mirrored from iPhone) plus a pending-tap
/// queue the watch writes when the user logs water from the wrist. iPhone
/// reconciles the queue into SwiftData at next foreground.
///
/// Until the App Group entitlement ships, falls back to `.standard`
/// (per-process — watch and phone won't actually share state, but the
/// surface compiles + behaves predictably for unit tests).
public enum WatchHydrationGlanceStore {

    public static let totalKey = "watch.hydration.todayMl"
    public static let dayKey = "watch.hydration.todayDay"
    public static let pendingKey = "watch.hydration.pendingMl"

    public static func defaultsForAppGroup() -> UserDefaults {
        UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    }

    public static func setTotal(
        _ milliliters: Int,
        on day: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = defaultsForAppGroup()
    ) {
        defaults.set(max(0, milliliters), forKey: totalKey)
        defaults.set(dayKeyString(for: day, calendar: calendar), forKey: dayKey)
    }

    public static func todayTotal(
        on day: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        in defaults: UserDefaults = defaultsForAppGroup()
    ) -> Int {
        let storedDay = defaults.string(forKey: dayKey) ?? ""
        guard storedDay == dayKeyString(for: day, calendar: calendar) else { return 0 }
        return max(0, defaults.integer(forKey: totalKey))
    }

    /// Append a pending tap. iPhone-side reconciler flushes these back into
    /// SwiftData and clears the queue.
    public static func appendPendingTap(
        amountMl: Int,
        in defaults: UserDefaults = defaultsForAppGroup()
    ) {
        guard amountMl > 0 else { return }
        var pending = defaults.array(forKey: pendingKey) as? [Int] ?? []
        pending.append(amountMl)
        defaults.set(pending, forKey: pendingKey)
    }

    public static func pendingTaps(in defaults: UserDefaults = defaultsForAppGroup()) -> [Int] {
        defaults.array(forKey: pendingKey) as? [Int] ?? []
    }

    public static func clearPending(in defaults: UserDefaults = defaultsForAppGroup()) {
        defaults.removeObject(forKey: pendingKey)
    }

    private static func dayKeyString(for date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}
