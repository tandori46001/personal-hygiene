import Foundation

/// Round-12 slice 19: ring buffer of the last 10 process launches so we can
/// detect silent OS-driven restarts (low-memory kills, system updates,
/// crashes). Each entry is `(launchedAt, durationSeconds)` where `durationSeconds`
/// is the lifetime *of the previous launch* — recorded when this launch starts.
public enum ProcessLaunchHistoryStore {

    public static let key = "process.launchHistory"
    public static let capacity = 10

    public struct Entry: Codable, Equatable, Sendable, Identifiable {
        public let id: UUID
        public let launchedAt: Date
        /// Duration in seconds of the previous launch. `nil` for the very
        /// first launch ever recorded.
        public let previousDurationSeconds: TimeInterval?

        public init(
            id: UUID = UUID(),
            launchedAt: Date,
            previousDurationSeconds: TimeInterval?
        ) {
            self.id = id
            self.launchedAt = launchedAt
            self.previousDurationSeconds = previousDurationSeconds
        }
    }

    public static func history(defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    public static func recordLaunch(
        at now: Date = Date(),
        in defaults: UserDefaults = .standard
    ) {
        var current = history(defaults: defaults)
        let previousDuration: TimeInterval? = {
            guard let last = current.first else { return nil }
            return now.timeIntervalSince(last.launchedAt)
        }()
        current.insert(
            Entry(launchedAt: now, previousDurationSeconds: previousDuration),
            at: 0
        )
        if current.count > capacity { current = Array(current.prefix(capacity)) }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
