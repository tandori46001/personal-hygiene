import Foundation

/// User-configured Deep Focus window that fires on its own schedule rather
/// than being tied to a routine block. Stored as a value type so the Settings
/// UI can edit it freely without going through SwiftData.
public struct ScheduledFocusWindow: Codable, Equatable, Hashable, Identifiable, Sendable {

    public var id: UUID
    public var label: String
    /// `Calendar.weekday` values (1 = Sunday, 7 = Saturday). Empty array means
    /// the schedule is disabled — the editor uses this to "pause" without
    /// deleting.
    public var weekdays: Set<Int>
    public var startMinutesFromMidnight: Int
    public var endMinutesFromMidnight: Int

    public init(
        id: UUID = UUID(),
        label: String,
        weekdays: Set<Int>,
        startMinutesFromMidnight: Int,
        endMinutesFromMidnight: Int
    ) {
        self.id = id
        self.label = label
        self.weekdays = weekdays
        self.startMinutesFromMidnight = startMinutesFromMidnight
        self.endMinutesFromMidnight = endMinutesFromMidnight
    }

    public var isActive: Bool {
        !weekdays.isEmpty && endMinutesFromMidnight > startMinutesFromMidnight
    }

    /// The window covering `date` if today's weekday is enabled.
    public func window(on date: Date, calendar: Calendar) -> DeepFocusFilter.FocusWindow? {
        guard isActive else { return nil }
        let weekday = calendar.component(.weekday, from: date)
        guard weekdays.contains(weekday) else { return nil }
        let dayStart = calendar.startOfDay(for: date)
        guard
            let start = calendar.date(byAdding: .minute, value: startMinutesFromMidnight, to: dayStart),
            let end = calendar.date(byAdding: .minute, value: endMinutesFromMidnight, to: dayStart)
        else { return nil }
        return DeepFocusFilter.FocusWindow(blockTitle: label, start: start, end: end)
    }
}

public protocol FocusScheduleStore: Sendable {
    func windows() -> [ScheduledFocusWindow]
    func setWindows(_ windows: [ScheduledFocusWindow])
}

extension FocusScheduleStore {

    public func upsert(_ window: ScheduledFocusWindow) {
        var current = windows()
        if let idx = current.firstIndex(where: { $0.id == window.id }) {
            current[idx] = window
        } else {
            current.append(window)
        }
        setWindows(current)
    }

    public func delete(id: UUID) {
        setWindows(windows().filter { $0.id != id })
    }
}

public final class UserDefaultsFocusScheduleStore: FocusScheduleStore, @unchecked Sendable {

    public static let storageKey = "personal-hygiene.focusSchedules.v1"

    private let defaults: UserDefaults
    private let lock = NSLock()

    /// Default initializer uses `UserDefaults.standard`. Pass an
    /// `AppGroup`-scoped suite (`UserDefaults(suiteName: AppGroup.suiteName)`)
    /// when both the app and its widget extension need to read the schedule
    /// from a shared sandbox; once the app group entitlement is added this is
    /// the only line the widget needs to flip.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Convenience that reads from the app-group container if the suite can be
    /// constructed (entitlement is present), falling back to `.standard`.
    public static func appGroupOrStandard() -> UserDefaultsFocusScheduleStore {
        if let suite = UserDefaults(suiteName: AppGroup.suiteName) {
            return UserDefaultsFocusScheduleStore(defaults: suite)
        }
        return UserDefaultsFocusScheduleStore()
    }

    public func windows() -> [ScheduledFocusWindow] {
        lock.lock(); defer { lock.unlock() }
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([ScheduledFocusWindow].self, from: data)) ?? []
    }

    public func setWindows(_ windows: [ScheduledFocusWindow]) {
        lock.lock(); defer { lock.unlock() }
        let data = (try? JSONEncoder().encode(windows)) ?? Data()
        defaults.set(data, forKey: Self.storageKey)
    }
}

public final class InMemoryFocusScheduleStore: FocusScheduleStore, @unchecked Sendable {
    private var entries: [ScheduledFocusWindow] = []
    private let lock = NSLock()

    public init(initial: [ScheduledFocusWindow] = []) {
        self.entries = initial
    }

    public func windows() -> [ScheduledFocusWindow] {
        lock.lock(); defer { lock.unlock() }
        return entries
    }

    public func setWindows(_ windows: [ScheduledFocusWindow]) {
        lock.lock(); defer { lock.unlock() }
        entries = windows
    }
}
