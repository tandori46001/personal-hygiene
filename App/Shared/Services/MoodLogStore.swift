import Foundation

/// Round-19 slice T5.20: minimal one-tap mood logger surfaced on the Today
/// screen. We persist a single rolling array of `(mood, recordedAt)` entries
/// in `UserDefaults` (no SwiftData model — moods are throwaway data the user
/// can opt out of by clearing settings, and we want to avoid CloudKit sync
/// overhead for ephemeral context).
public enum MoodLogStore {

    public static let key = "today.moodLog"
    public static let capacity = 30

    public enum Mood: String, CaseIterable, Sendable {
        case great
        case good
        case okay
        case bad
        case awful

        public var emoji: String {
            switch self {
            case .great: "😄"
            case .good: "🙂"
            case .okay: "😐"
            case .bad: "🙁"
            case .awful: "😞"
            }
        }
    }

    public struct Entry: Codable, Equatable, Sendable {
        public let mood: String
        public let recordedAt: Date

        public init(mood: Mood, recordedAt: Date = Date()) {
            self.mood = mood.rawValue
            self.recordedAt = recordedAt
        }

        public var moodCase: Mood? { Mood(rawValue: mood) }
    }

    public static func entries(defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    public static func record(
        _ mood: Mood,
        now: Date = Date(),
        in defaults: UserDefaults = .standard
    ) {
        var existing = entries(defaults: defaults)
        existing.insert(Entry(mood: mood, recordedAt: now), at: 0)
        if existing.count > capacity { existing = Array(existing.prefix(capacity)) }
        if let payload = try? JSONEncoder().encode(existing) {
            defaults.set(payload, forKey: key)
        }
    }

    /// Most recent entry recorded *today* (per the supplied calendar). The
    /// Today UI uses this to highlight the chosen emoji so re-tapping the
    /// same chip is idempotent and the user sees their selection persists.
    public static func todayEntry(
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        defaults: UserDefaults = .standard
    ) -> Entry? {
        let day = calendar.startOfDay(for: now)
        return entries(defaults: defaults).first { calendar.startOfDay(for: $0.recordedAt) == day }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
