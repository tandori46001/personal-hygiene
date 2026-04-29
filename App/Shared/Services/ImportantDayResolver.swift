import Foundation

/// Round 27 (WS-B B6) — resolves enabled `ImportantDay` rows against
/// "today's" date so TodayView can render a sorted, deduplicated list.
public enum ImportantDayResolver {

    public struct UpcomingEntry: Equatable, Sendable, Identifiable {
        public let id: UUID
        public let name: String
        public let nextOccurrence: Date
        public let daysUntil: Int
        public let isCustom: Bool

        public init(id: UUID, name: String, nextOccurrence: Date, daysUntil: Int, isCustom: Bool) {
            self.id = id
            self.name = name
            self.nextOccurrence = nextOccurrence
            self.daysUntil = daysUntil
            self.isCustom = isCustom
        }
    }

    /// Returns entries whose next occurrence falls in [today, today+windowDays].
    /// Sorted ascending by date.
    public static func upcoming(
        days: [ImportantDay],
        on now: Date,
        windowDays: Int,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [UpcomingEntry] {
        let today = calendar.startOfDay(for: now)
        var entries: [UpcomingEntry] = []
        for day in days {
            guard
                let rule = day.dayRule,
                let next = rule.nextOccurrence(onOrAfter: today, calendar: calendar)
            else { continue }
            let daysUntil = calendar.dateComponents([.day], from: today, to: next).day ?? Int.max
            if daysUntil >= 0 && daysUntil <= windowDays {
                entries.append(
                    UpcomingEntry(
                        id: day.id,
                        name: day.name,
                        nextOccurrence: next,
                        daysUntil: daysUntil,
                        isCustom: day.isCustom
                    )
                )
            }
        }
        return entries.sorted { $0.nextOccurrence < $1.nextOccurrence }
    }
}
