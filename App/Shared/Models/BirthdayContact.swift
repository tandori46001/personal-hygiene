import Foundation

/// Lightweight value-type DTO of a contact's birthday. Used so the rest of
/// the app does not depend on the `Contacts` framework directly.
public struct BirthdayContact: Equatable, Hashable, Sendable, Identifiable {

    public var id: String { identifier }

    public let identifier: String
    public let displayName: String
    /// Birth month (1-12).
    public let month: Int
    /// Birth day-of-month (1-31).
    public let day: Int
    /// Birth year, when known. Often `nil` because users frequently store
    /// birthdays without a year for privacy.
    public let year: Int?

    public init(identifier: String, displayName: String, month: Int, day: Int, year: Int?) {
        self.identifier = identifier
        self.displayName = displayName
        self.month = month
        self.day = day
        self.year = year
    }

    /// Birthday's date in the given year (calendar-aware), or `nil` if month/day
    /// are out of range.
    public func date(in year: Int, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date
    }
}
