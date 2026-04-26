import Foundation

/// Tracks per-day "skip" overrides for individual blocks. The schedule is
/// driven by the active template, but users sometimes want to skip a block
/// for a single day without permanently editing the template — this store
/// captures that intent.
///
/// Skips are scoped to a `(blockID, ISO day-key)` pair so they expire
/// automatically on the next day. Persisted in `UserDefaults` so the next
/// app launch on the same calendar day still sees the skip.
public protocol BlockSkipStore: Sendable {
    func isSkipped(blockID: UUID, on date: Date, calendar: Calendar) -> Bool
    func skip(blockID: UUID, on date: Date, calendar: Calendar)
    func unskip(blockID: UUID, on date: Date, calendar: Calendar)
    /// Drop entries older than `keepLastDays` days. Called from refresh paths.
    func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int)
}

extension BlockSkipStore {

    public func isSkipped(blockID: UUID, on date: Date) -> Bool {
        isSkipped(blockID: blockID, on: date, calendar: .autoupdatingCurrent)
    }

    public func skip(blockID: UUID, on date: Date) {
        skip(blockID: blockID, on: date, calendar: .autoupdatingCurrent)
    }

    public func unskip(blockID: UUID, on date: Date) {
        unskip(blockID: blockID, on: date, calendar: .autoupdatingCurrent)
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}

public final class UserDefaultsBlockSkipStore: BlockSkipStore, @unchecked Sendable {

    public static let storageKey = "personal-hygiene.blockSkips.v1"

    private let defaults: UserDefaults
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func isSkipped(blockID: UUID, on date: Date, calendar: Calendar) -> Bool {
        let key = compositeKey(blockID: blockID, date: date, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        let set = readKeys()
        return set.contains(key)
    }

    public func skip(blockID: UUID, on date: Date, calendar: Calendar) {
        let key = compositeKey(blockID: blockID, date: date, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        var set = readKeys()
        set.insert(key)
        writeKeys(set)
    }

    public func unskip(blockID: UUID, on date: Date, calendar: Calendar) {
        let key = compositeKey(blockID: blockID, date: date, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        var set = readKeys()
        set.remove(key)
        writeKeys(set)
    }

    public func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int = 7) {
        guard let cutoff = calendar.date(byAdding: .day, value: -keepLastDays, to: calendar.startOfDay(for: now))
        else { return }
        let cutoffKey = Self.dayKey(for: cutoff, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        let set = readKeys()
        let kept = set.filter { entry in
            guard let dayPart = entry.split(separator: "|").last.map(String.init) else { return true }
            return dayPart >= cutoffKey
        }
        writeKeys(kept)
    }

    private func compositeKey(blockID: UUID, date: Date, calendar: Calendar) -> String {
        "\(blockID.uuidString)|\(Self.dayKey(for: date, calendar: calendar))"
    }

    private func readKeys() -> Set<String> {
        let array = defaults.array(forKey: Self.storageKey) as? [String] ?? []
        return Set(array)
    }

    private func writeKeys(_ set: Set<String>) {
        defaults.set(Array(set), forKey: Self.storageKey)
    }
}

public final class InMemoryBlockSkipStore: BlockSkipStore, @unchecked Sendable {
    private var keys: Set<String> = []
    private let lock = NSLock()

    public init() {}

    public func isSkipped(blockID: UUID, on date: Date, calendar: Calendar) -> Bool {
        let key = compositeKey(blockID: blockID, date: date, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        return keys.contains(key)
    }

    public func skip(blockID: UUID, on date: Date, calendar: Calendar) {
        let key = compositeKey(blockID: blockID, date: date, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        keys.insert(key)
    }

    public func unskip(blockID: UUID, on date: Date, calendar: Calendar) {
        let key = compositeKey(blockID: blockID, date: date, calendar: calendar)
        lock.lock(); defer { lock.unlock() }
        keys.remove(key)
    }

    public func purgeStale(before now: Date, calendar: Calendar, keepLastDays: Int) {
        // No-op for in-memory: tests construct fresh instances per case.
    }

    private func compositeKey(blockID: UUID, date: Date, calendar: Calendar) -> String {
        "\(blockID.uuidString)|\(Self.dayKey(for: date, calendar: calendar))"
    }
}
