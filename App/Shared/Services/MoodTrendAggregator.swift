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
}
