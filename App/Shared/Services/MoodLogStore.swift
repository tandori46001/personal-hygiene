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

    /// Round-22 slice T4.21: number of consecutive days ending on `now`
    /// where the dominant mood is at least `minimum` (defaults to `.okay`).
    /// "Dominant" = first entry recorded that day. A day with no entry
    /// breaks the streak.
    public static func streakDays(
        atLeast minimum: Mood = .okay,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        defaults: UserDefaults = .standard
    ) -> Int {
        let log = entries(defaults: defaults)
        var cursor = calendar.startOfDay(for: now)
        var streak = 0
        let minimumScore = MoodTrendAggregator.score(for: minimum)
        while true {
            let entry = log.first {
                calendar.startOfDay(for: $0.recordedAt) == cursor
            }
            guard let mood = entry?.moodCase else { break }
            guard MoodTrendAggregator.score(for: mood) >= minimumScore else { break }
            streak += 1
            guard let prior = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prior
        }
        return streak
    }

    /// Round-20 slice T2.7: count of entries marked `.good` or `.great` whose
    /// `recordedAt` falls within the trailing `days` (default 7) up to `now`.
    /// Multiple records on the same day count once each — the user explicitly
    /// re-tapping a chip still expresses ongoing positive mood.
    public static func goodDaysCount(
        in days: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        defaults: UserDefaults = .standard
    ) -> Int {
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else { return 0 }
        return entries(defaults: defaults).filter { entry in
            entry.recordedAt >= cutoff
                && entry.recordedAt <= now
                && (entry.moodCase == .good || entry.moodCase == .great)
        }.count
    }

    /// Round-20 slice T2.11: per-line CSV export sorted newest-first.
    /// Header is `recordedAt,mood`. Used by Diagnostics → Export mood log.
    public static func exportCSV(
        defaults: UserDefaults = .standard,
        formatter: ISO8601DateFormatter = ISO8601DateFormatter()
    ) -> String {
        var lines = ["recordedAt,mood"]
        for entry in entries(defaults: defaults) {
            lines.append("\(formatter.string(from: entry.recordedAt)),\(entry.mood)")
        }
        return lines.joined(separator: "\n")
    }

    /// Round-21 slice T2.12: variant of `exportCSV` whose header is rendered
    /// in the user's preferred language so a copy/paste into a spreadsheet
    /// matches the rest of the UI. Defaults to the legacy English header
    /// when no localization is supplied. The data rows are unchanged — they
    /// always carry the canonical English mood `rawValue` so a CSV is round-
    /// trippable across locales.
    public static func exportLocalizedCSV(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main,
        formatter: ISO8601DateFormatter = ISO8601DateFormatter()
    ) -> String {
        let header = bundle.localizedString(forKey: "moodLog.csv.header", value: "recordedAt,mood", table: nil)
        var lines = [header]
        for entry in entries(defaults: defaults) {
            lines.append("\(formatter.string(from: entry.recordedAt)),\(entry.mood)")
        }
        return lines.joined(separator: "\n")
    }
}
