import Foundation

/// Round-21 slice T2.8: bins `MoodLogStore.Entry` records into per-day buckets
/// for the 30-day trend chart in Settings → Mood log → Trend.
///
/// Each bin holds the *average mood score* (great = 5, awful = 1) for that
/// day plus the count. Days with no entries are emitted with `count = 0` and
/// `score = nil` so the chart can plot gaps.
public enum MoodTrendAggregator {

    public struct DailyBin: Equatable, Sendable {
        public let day: Date
        public let count: Int
        public let score: Double?
    }

    public static func score(for mood: MoodLogStore.Mood) -> Int {
        switch mood {
        case .great: 5
        case .good: 4
        case .okay: 3
        case .bad: 2
        case .awful: 1
        }
    }

    public static func bins(
        from entries: [MoodLogStore.Entry],
        days: Int = 30,
        endingAt now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [DailyBin] {
        let today = calendar.startOfDay(for: now)
        guard let earliest = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return []
        }

        var totalsByDay: [Date: (sum: Int, count: Int)] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.recordedAt)
            guard day >= earliest, day <= today, let mood = entry.moodCase else { continue }
            let cell = totalsByDay[day] ?? (0, 0)
            totalsByDay[day] = (cell.sum + score(for: mood), cell.count + 1)
        }

        var result: [DailyBin] = []
        var cursor = earliest
        while cursor <= today {
            if let cell = totalsByDay[cursor] {
                result.append(DailyBin(day: cursor, count: cell.count, score: Double(cell.sum) / Double(cell.count)))
            } else {
                result.append(DailyBin(day: cursor, count: 0, score: nil))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    /// Round-22 slice T4.20: average mood score over a trailing window. Nil
    /// when the window has no scored days.
    public static func windowAverage(
        from entries: [MoodLogStore.Entry],
        days: Int,
        endingAt now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double? {
        let scored = bins(from: entries, days: days, endingAt: now, calendar: calendar)
            .compactMap(\.score)
        guard !scored.isEmpty else { return nil }
        return scored.reduce(0, +) / Double(scored.count)
    }

    /// Round-21 slice T2.9 (moved here in round 22 so the watch target,
    /// which only compiles `Shared/`, can call it from `WatchMoodStrip`).
    /// Rounds a daily-average score to the nearest mood emoji.
    public static func symbol(for score: Double) -> String {
        // Clamp the rounded score into [1, 5] so out-of-range values still
        // resolve to a meaningful emoji instead of falling through.
        let rounded = max(1, min(5, Int(score.rounded())))
        switch rounded {
        case 5: return MoodLogStore.Mood.great.emoji
        case 4: return MoodLogStore.Mood.good.emoji
        case 3: return MoodLogStore.Mood.okay.emoji
        case 2: return MoodLogStore.Mood.bad.emoji
        default: return MoodLogStore.Mood.awful.emoji
        }
    }

    /// Round-22 slice T4.20: trailing-7-day average minus the previous
    /// 7-day average. Positive = trending happier, negative = trending
    /// worse, nil = insufficient data on either side.
    public static func weeklyDelta(
        from entries: [MoodLogStore.Entry],
        endingAt now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double? {
        guard let thisWeek = windowAverage(from: entries, days: 7, endingAt: now, calendar: calendar)
        else { return nil }
        guard let priorEnd = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
        guard let priorWeek = windowAverage(from: entries, days: 7, endingAt: priorEnd, calendar: calendar)
        else { return nil }
        return thisWeek - priorWeek
    }
}
