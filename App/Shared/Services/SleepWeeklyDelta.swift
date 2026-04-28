import Foundation

/// Round-24 slice T3.15: trailing-7-day average sleep duration vs prior
/// 7-day average. Positive = sleeping more this week; negative = sleeping
/// less. Caller supplies the per-day duration log.
public enum SleepWeeklyDelta {

    public struct DailySleep: Equatable, Sendable {
        public let day: Date
        public let durationMinutes: Int
    }

    public struct Summary: Equatable, Sendable {
        public let thisWeekMinutes: Double
        public let priorWeekMinutes: Double
        public var delta: Double { thisWeekMinutes - priorWeekMinutes }
    }

    public static func summarize(
        log: [DailySleep],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Summary? {
        let today = calendar.startOfDay(for: now)
        guard let cutoffThis = calendar.date(byAdding: .day, value: -7, to: today),
              let cutoffPrior = calendar.date(byAdding: .day, value: -14, to: today)
        else { return nil }
        let thisWeek = log.filter { $0.day >= cutoffThis && $0.day <= today }
        let priorWeek = log.filter { $0.day >= cutoffPrior && $0.day < cutoffThis }
        guard !thisWeek.isEmpty, !priorWeek.isEmpty else { return nil }
        let thisAvg = Double(thisWeek.map(\.durationMinutes).reduce(0, +)) / Double(thisWeek.count)
        let priorAvg = Double(priorWeek.map(\.durationMinutes).reduce(0, +)) / Double(priorWeek.count)
        return Summary(thisWeekMinutes: thisAvg, priorWeekMinutes: priorAvg)
    }
}
