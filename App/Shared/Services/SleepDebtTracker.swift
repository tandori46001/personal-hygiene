import Foundation

/// Round-25 slice T3.21: rolling 7-day "sleep debt" relative to a target.
/// Negative debt = sleeping more than target; positive = deficit. Pure
/// helper feeding `SleepDebtTrackerCaption`.
public enum SleepDebtTracker {

    public static let defaultTargetMinutes = 480

    public struct Summary: Equatable, Sendable {
        public let debtMinutes: Int
        public let nightsCounted: Int
        public let target: Int
    }

    public static func debt(
        nights: [SleepNight],
        targetMinutes: Int = defaultTargetMinutes,
        windowDays: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Summary? {
        let today = calendar.startOfDay(for: now)
        guard let cutoff = calendar.date(byAdding: .day, value: -windowDays, to: today) else {
            return nil
        }
        let windowed = nights.filter {
            $0.nightOf >= cutoff && $0.nightOf <= today
        }
        guard !windowed.isEmpty else { return nil }
        let totalActual = windowed.map(\.durationMinutes).reduce(0, +)
        let totalTarget = targetMinutes * windowed.count
        return Summary(
            debtMinutes: totalTarget - totalActual,
            nightsCounted: windowed.count,
            target: targetMinutes
        )
    }
}
