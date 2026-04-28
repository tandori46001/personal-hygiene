import Foundation

/// Round-22 slice T6.33: pure helper that turns the App-Group mood log
/// into 7 daily strip cells for the watch settings glance. Mirrors
/// `TodayView.moodWeekStrip(...)` but lives in `Shared/` so the watch
/// target can call it without dragging in the iPhone view code.
public enum WatchMoodStrip {

    public struct Cell: Equatable, Sendable {
        public let day: Date
        public let symbol: String
    }

    public static func cells(
        days: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent,
        defaults: UserDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    ) -> [Cell] {
        let entries = MoodLogStore.entries(defaults: defaults)
        let bins = MoodTrendAggregator.bins(
            from: entries,
            days: days,
            endingAt: now,
            calendar: calendar
        )
        return bins.map { bin in
            let symbol: String
            if let score = bin.score {
                symbol = MoodTrendAggregator.symbol(for: score)
            } else {
                symbol = "·"
            }
            return Cell(day: bin.day, symbol: symbol)
        }
    }
}
