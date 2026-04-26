import Foundation

/// Tracks "this notification was snoozed at least once today" so the Today
/// row (and other module surfaces) can show a small badge. Same keying scheme
/// as `BlockSkipStore`: a `(source, key, ISO day-key)` triple, persisted to
/// `UserDefaults` so the next launch on the same calendar day still shows
/// the indicator.
public protocol BlockSnoozeStore: Sendable {
    // Routine-block source (legacy API kept to avoid breaking call sites).
    func isSnoozed(blockID: UUID, on date: Date, calendar: Calendar) -> Bool
    func markSnoozed(blockID: UUID, dayKey: String)

    // Any-source API (routine, hydration, trip-milestone).
    func isSnoozed(source: BlockSnoozeSource, key: String, on date: Date, calendar: Calendar) -> Bool
    func markSnoozed(source: BlockSnoozeSource, key: String, dayKey: String)

    /// Drop entries older than `keepLastDays` days. Called from refresh paths.
    func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int)
}

extension BlockSnoozeStore {

    public func isSnoozed(blockID: UUID, on date: Date) -> Bool {
        isSnoozed(blockID: blockID, on: date, calendar: .autoupdatingCurrent)
    }

    public func isSnoozed(source: BlockSnoozeSource, key: String, on date: Date) -> Bool {
        isSnoozed(source: source, key: key, on: date, calendar: .autoupdatingCurrent)
    }

    /// Records a snooze derived from a parsed notification identifier — handles
    /// every kind in a single call site.
    public func markSnoozed(
        parsed: ParsedNotificationIdentifier,
        on date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        switch parsed {
        case .routine(let blockID, let storedDayKey):
            // Prefer the dayKey embedded in the identifier (matches NotificationFactory output).
            markSnoozed(blockID: blockID, dayKey: storedDayKey)
        case .hydration(_, let index):
            markSnoozed(source: .hydration, key: String(index), dayKey: dayKey)
        case .milestone(let milestoneID):
            markSnoozed(source: .milestone, key: milestoneID.uuidString, dayKey: dayKey)
        }
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// Encodes a per-source key as `{source}|{key}|{dayKey}` so the underlying
    /// flat `Set<String>` stays compatible with the legacy routine entries
    /// (which use `{uuid}|{dayKey}` with no source prefix).
    static func encodedKey(source: BlockSnoozeSource, key: String, dayKey: String) -> String {
        "\(source.rawValue)|\(key)|\(dayKey)"
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
        let legacyKey = "\(blockID.uuidString)|\(Self.dayKey(for: date, calendar: calendar))"
        let modernKey = Self.encodedKey(
            source: .routine,
            key: blockID.uuidString,
            dayKey: Self.dayKey(for: date, calendar: calendar)
        )
        lock.lock(); defer { lock.unlock() }
        let stored = readKeys()
        return stored.contains(legacyKey) || stored.contains(modernKey)
    }

    public func markSnoozed(blockID: UUID, dayKey: String) {
        let key = "\(blockID.uuidString)|\(dayKey)"
        lock.lock(); defer { lock.unlock() }
        var set = readKeys()
        set.insert(key)
        writeKeys(set)
    }

    public func isSnoozed(source: BlockSnoozeSource, key: String, on date: Date, calendar: Calendar) -> Bool {
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        let modernKey = Self.encodedKey(source: source, key: key, dayKey: dayKey)
        lock.lock(); defer { lock.unlock() }
        let stored = readKeys()
        if stored.contains(modernKey) { return true }
        // Routine source can also be present in the legacy `{uuid}|{dayKey}` format.
        if source == .routine, stored.contains("\(key)|\(dayKey)") { return true }
        return false
    }

    public func markSnoozed(source: BlockSnoozeSource, key: String, dayKey: String) {
        let encoded = Self.encodedKey(source: source, key: key, dayKey: dayKey)
        lock.lock(); defer { lock.unlock() }
        var set = readKeys()
        set.insert(encoded)
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
        let legacyKey = "\(blockID.uuidString)|\(Self.dayKey(for: date, calendar: calendar))"
        let modernKey = Self.encodedKey(
            source: .routine,
            key: blockID.uuidString,
            dayKey: Self.dayKey(for: date, calendar: calendar)
        )
        lock.lock(); defer { lock.unlock() }
        return keys.contains(legacyKey) || keys.contains(modernKey)
    }

    public func markSnoozed(blockID: UUID, dayKey: String) {
        let key = "\(blockID.uuidString)|\(dayKey)"
        lock.lock(); defer { lock.unlock() }
        keys.insert(key)
    }

    public func isSnoozed(source: BlockSnoozeSource, key: String, on date: Date, calendar: Calendar) -> Bool {
        let dayKey = Self.dayKey(for: date, calendar: calendar)
        let modernKey = Self.encodedKey(source: source, key: key, dayKey: dayKey)
        lock.lock(); defer { lock.unlock() }
        if keys.contains(modernKey) { return true }
        if source == .routine, keys.contains("\(key)|\(dayKey)") { return true }
        return false
    }

    public func markSnoozed(source: BlockSnoozeSource, key: String, dayKey: String) {
        let encoded = Self.encodedKey(source: source, key: key, dayKey: dayKey)
        lock.lock(); defer { lock.unlock() }
        keys.insert(encoded)
    }

    public func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int) {
        // No-op for in-memory: tests construct fresh instances per case.
    }
}

/// Source module that produced a notification — used by `BlockSnoozeStore` so
/// per-module badges (routine / hydration / milestone) stay scoped.
public enum BlockSnoozeSource: String, CaseIterable, Sendable {
    case routine
    case hydration
    case milestone
}

/// Parsed shape of a notification identifier emitted by any of the app's
/// notification factories. The cases mirror `BlockSnoozeSource`.
public enum ParsedNotificationIdentifier: Equatable, Sendable {
    case routine(blockID: UUID, dayKey: String)
    case hydration(dayKey: String, index: Int)
    case milestone(milestoneID: UUID)

    public var source: BlockSnoozeSource {
        switch self {
        case .routine: return .routine
        case .hydration: return .hydration
        case .milestone: return .milestone
        }
    }
}

/// Helper to recover the source + payload from any of the app's notification
/// identifiers. Adding a new `BlockSnoozeSource` here without updating the
/// switch is a compile error — see L002 in `LESSONS.md`.
public enum BlockNotificationIdentifier {

    /// Backwards-compatible parser for routine block identifiers only. New
    /// callers should prefer `parseAny(_:)` and switch on the result.
    public static func parse(_ identifier: String) -> (blockID: UUID, dayKey: String)? {
        guard case let .routine(blockID, dayKey) = parseAny(identifier) else { return nil }
        return (blockID, dayKey)
    }

    /// Parses any of the app's known notification identifiers. Returns `nil`
    /// for snooze re-fires (suffixed with `.snooze.<timestamp>`) and unknown
    /// shapes.
    public static func parseAny(_ identifier: String) -> ParsedNotificationIdentifier? {
        // Snooze re-fires reuse the original identifier with a `.snooze.<ts>`
        // suffix. Strip it before matching so the original kind is recognized.
        let normalized: String = {
            guard let range = identifier.range(of: ".snooze.") else { return identifier }
            return String(identifier[..<range.lowerBound])
        }()

        for source in BlockSnoozeSource.allCases {
            switch source {
            case .routine:
                if let parsed = parseRoutine(normalized) {
                    return parsed
                }
            case .hydration:
                if let parsed = parseHydration(normalized) {
                    return parsed
                }
            case .milestone:
                if let parsed = parseMilestone(normalized) {
                    return parsed
                }
            }
        }
        return nil
    }

    private static func parseRoutine(_ identifier: String) -> ParsedNotificationIdentifier? {
        let prefix = NotificationFactory.identifierPrefix
        guard identifier.hasPrefix(prefix) else { return nil }
        let trimmed = identifier.dropFirst(prefix.count)
        let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2,
              let uuid = UUID(uuidString: String(parts[0]))
        else { return nil }
        return .routine(blockID: uuid, dayKey: String(parts[1]))
    }

    private static func parseHydration(_ identifier: String) -> ParsedNotificationIdentifier? {
        let prefix = HydrationNotificationFactory.identifierPrefix
        guard identifier.hasPrefix(prefix) else { return nil }
        let trimmed = identifier.dropFirst(prefix.count)
        // Format: "{YYYY-MM-DD}.{index}" — dayKey contains hyphens, not dots.
        let parts = trimmed.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2,
              let index = Int(parts[1])
        else { return nil }
        return .hydration(dayKey: String(parts[0]), index: index)
    }

    private static func parseMilestone(_ identifier: String) -> ParsedNotificationIdentifier? {
        let prefix = TripMilestoneNotificationFactory.identifierPrefix
        guard identifier.hasPrefix(prefix) else { return nil }
        let trimmed = identifier.dropFirst(prefix.count)
        guard let uuid = UUID(uuidString: String(trimmed)) else { return nil }
        return .milestone(milestoneID: uuid)
    }
}
