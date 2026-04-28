import Foundation

/// Round-23 slice T2.12: 7-column × N-row calendar heatmap source. Each
/// row is a calendar week (Sun→Sat by default), each column a weekday.
/// Cells carry the trailing-window day's average score; nil = no entry.
public enum MoodHeatmapAggregator {

    public struct Cell: Equatable, Sendable {
        public let day: Date
        public let weekdayIndex: Int
        public let score: Double?
    }

    public struct Row: Equatable, Sendable {
        public let weekStart: Date
        public let cells: [Cell?]
    }

    public static func rows(
        from entries: [MoodLogStore.Entry],
        weeks: Int = 6,
        endingAt now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Row] {
        let bins = MoodTrendAggregator.bins(
            from: entries,
            days: max(7, weeks * 7),
            endingAt: now,
            calendar: calendar
        )
        var binsByDay: [Date: MoodTrendAggregator.DailyBin] = [:]
        for bin in bins {
            binsByDay[calendar.startOfDay(for: bin.day)] = bin
        }
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today)
        let rollback = (weekday - calendar.firstWeekday + 7) % 7
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -rollback, to: today) else {
            return []
        }
        var rows: [Row] = []
        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .day, value: -7 * weekOffset, to: currentWeekStart)
            else { continue }
            var cells: [Cell?] = []
            for column in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: column, to: weekStart) else {
                    cells.append(nil)
                    continue
                }
                if day > today {
                    cells.append(nil)
                    continue
                }
                let score = binsByDay[calendar.startOfDay(for: day)]?.score
                cells.append(Cell(day: day, weekdayIndex: column, score: score))
            }
            rows.append(Row(weekStart: weekStart, cells: cells))
        }
        return rows
    }
}
