import Foundation

/// Tracks "this block was snoozed at least once today" so the Today row can
/// show a small badge. Same keying scheme as `BlockSkipStore`: a `(blockID,
/// ISO day-key)` pair, persisted to `UserDefaults` so the next launch on the
/// same calendar day still shows the indicator.
public protocol BlockSnoozeStore: Sendable {
    func isSnoozed(blockID: UUID, on date: Date, calendar: Calendar) -> Bool
    func markSnoozed(blockID: UUID, dayKey: String)
    /// Drop entries older than `keepLastDays` days. Called from refresh paths.
    func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int)
}

extension BlockSnoozeStore {

    public func isSnoozed(blockID: UUID, on date: Date) -> Bool {
        isSnoozed(blockID: blockID, on: date, calendar: .autoupdatingCurrent)
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}

public final class UserDefaultsBlockSnoozeStore: BlockSnoozeStore, @unchecked Sendable {

    public static let storageKey = "personal-hygiene.blockSnoozes.v1"

    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isSnoozed(blockID: UUID, on date: Date, calendar: Calendar) -> Bool {
        let key = "\(blockID.uuidString)|\(Self.dayKey(for: date, calendar: calendar))"
        lock.lock(); defer { lock.unlock() }
        return readKeys().contains(key)
    }

    public func markSnoozed(blockID: UUID, dayKey: String) {
        let key = "\(blockID.uuidString)|\(dayKey)"
        lock.lock(); defer { lock.unlock() }
        var set = readKeys()
        set.insert(key)
        writeKeys(set)
    }

    public func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int = 7) {
        guard let cutoff = calendar.date(byAdding: .day, value: -keepLastDays, to: calendar.startOfDay(for: now))
        else { return }
        let cutoffKey = Self.dayKey(for: cutoff, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        let kept = readKeys().filter { entry in
            guard let day = entry.split(separator: "|").last.map(String.init) else { return true }
            return day >= cutoffKey
        }
        writeKeys(kept)
    }

    private func readKeys() -> Set<String> {
        let array = defaults.array(forKey: Self.storageKey) as? [String] ?? []
        return Set(array)
    }

    private func writeKeys(_ set: Set<String>) {
        defaults.set(Array(set), forKey: Self.storageKey)
    }
}

public final class InMemoryBlockSnoozeStore: BlockSnoozeStore, @unchecked Sendable {
    private var keys: Set<String> = []
    private let lock = NSLock()

    public init() {}

    public func isSnoozed(blockID: UUID, on date: Date, calendar: Calendar) -> Bool {
        let key = "\(blockID.uuidString)|\(Self.dayKey(for: date, calendar: calendar))"
        lock.lock(); defer { lock.unlock() }
        return keys.contains(key)
    }

    public func markSnoozed(blockID: UUID, dayKey: String) {
        let key = "\(blockID.uuidString)|\(dayKey)"
        lock.lock(); defer { lock.unlock() }
        keys.insert(key)
    }

    public func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int) {
        // No-op for in-memory: tests construct fresh instances per case.
    }
}

/// Helper to recover `(blockID, dayKey)` from a routine block notification
/// identifier formatted as `personal-hygiene.block.{UUID}.{YYYY-MM-DD}`.
public enum BlockNotificationIdentifier {

    public static func parse(_ identifier: String) -> (blockID: UUID, dayKey: String)? {
        let prefix = NotificationFactory.identifierPrefix
        guard identifier.hasPrefix(prefix) else { return nil }
        let trimmed = identifier.dropFirst(prefix.count)
        // Format is "<UUID>.<dayKey>" — UUIDs contain hyphens but no dots,
        // and dayKeys are "YYYY-MM-DD" with no dots either, so split on "."
        // with a max of 2 parts is unambiguous.
        let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2,
              let uuid = UUID(uuidString: String(parts[0]))
        else { return nil }
        return (uuid, String(parts[1]))
    }
}
