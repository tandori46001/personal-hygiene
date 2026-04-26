import Foundation

/// Pure helpers to compute the next occurrence of each birthday relative to
/// "now" so the UI can sort and group them consistently.
public enum UpcomingBirthdays {

    public struct Upcoming: Equatable, Sendable {
        public let contact: BirthdayContact
        public let nextOccurrence: Date
        public let daysUntil: Int

        public init(contact: BirthdayContact, nextOccurrence: Date, daysUntil: Int) {
            self.contact = contact
            self.nextOccurrence = nextOccurrence
            self.daysUntil = daysUntil
        }
    }

    /// Returns one entry per contact whose birthday falls within the next
    /// `windowDays`, sorted ascending by date. A birthday on `now` itself is
    /// included with `daysUntil == 0`.
    public static func upcoming(
        from contacts: [BirthdayContact],
        on now: Date,
        windowDays: Int,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Upcoming] {
        let today = calendar.startOfDay(for: now)
        let currentYear = calendar.component(.year, from: today)

        var results: [Upcoming] = []
        for contact in contacts {
            guard let next = nextOccurrence(of: contact, after: today, currentYear: currentYear, calendar: calendar)
            else { continue }
            let days = calendar.dateComponents([.day], from: today, to: next).day ?? Int.max
            if days >= 0 && days <= windowDays {
                results.append(Upcoming(contact: contact, nextOccurrence: next, daysUntil: days))
            }
        }
        return results.sorted { $0.nextOccurrence < $1.nextOccurrence }
    }

    private static func nextOccurrence(
        of contact: BirthdayContact,
        after today: Date,
        currentYear: Int,
        calendar: Calendar
    ) -> Date? {
        let thisYear = contact.date(in: currentYear, calendar: calendar)
        if let thisYear, calendar.startOfDay(for: thisYear) >= today {
            return calendar.startOfDay(for: thisYear)
        }
        if let nextYear = contact.date(in: currentYear + 1, calendar: calendar) {
            return calendar.startOfDay(for: nextYear)
        }
        return nil
    }
}
