import Foundation

/// Round-23 slice T2.8: groups `MoodLogStore.Entry` records into per-day
/// sections so the Settings disclosure can render `Section { … } header: { day }`
/// instead of a flat list. Pure helper — no UI imports.
public enum MoodLogGrouping {

    public struct DaySection: Equatable, Sendable {
        public let day: Date
        public let entries: [MoodLogStore.Entry]
    }

    public static func sections(
        from entries: [MoodLogStore.Entry],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [DaySection] {
        var bucket: [Date: [MoodLogStore.Entry]] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.recordedAt)
            bucket[day, default: []].append(entry)
        }
        return bucket
            .map { DaySection(day: $0.key, entries: $0.value.sorted { $0.recordedAt > $1.recordedAt }) }
            .sorted { $0.day > $1.day }
    }

    /// Round-23 slice T2.9: Today-only filter shortcut. Returns just the
    /// section for the current calendar day, or nil when no entries exist
    /// for today.
    public static func todaySection(
        from entries: [MoodLogStore.Entry],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> DaySection? {
        let today = calendar.startOfDay(for: now)
        let same = entries.filter { calendar.startOfDay(for: $0.recordedAt) == today }
        guard !same.isEmpty else { return nil }
        return DaySection(day: today, entries: same.sorted { $0.recordedAt > $1.recordedAt })
    }
}
