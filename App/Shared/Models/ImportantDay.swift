import Foundation
import SwiftData

/// Round 27 (WS-B) — non-birthday calendar dates the user wants surfaced
/// on Today. Two flavours:
///
/// 1. **Locale-seeded** at first launch from `Resources/ImportantDays/<locale>.json`:
///    Mother's / Father's day per region, New Year, Christmas, etc.
/// 2. **Custom** — anniversaries, named-day saints, personal milestones.
///
/// `dayRule` encodes how to resolve the calendar date each year. `enabled`
/// lets the user toggle a seeded day off without deleting it.
@Model
public final class ImportantDay {
    public var id: UUID
    public var name: String
    public var dayRuleData: Data
    public var localeRegion: String?
    public var enabled: Bool
    public var isCustom: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        dayRule: DayRule,
        localeRegion: String? = nil,
        enabled: Bool = true,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.dayRuleData = (try? JSONEncoder().encode(dayRule)) ?? Data()
        self.localeRegion = localeRegion
        self.enabled = enabled
        self.isCustom = isCustom
    }

    /// Decoded rule. `nil` if `dayRuleData` was tampered with.
    public var dayRule: DayRule? {
        get { try? JSONDecoder().decode(DayRule.self, from: dayRuleData) }
        set {
            guard let newValue, let encoded = try? JSONEncoder().encode(newValue) else { return }
            dayRuleData = encoded
        }
    }
}

/// Resolves to a concrete calendar date in any given year. Encoded as JSON
/// in `ImportantDay.dayRuleData` so we don't need a SwiftData enum migration.
/// JSON shape is `{ "type": "fixedMonthDay", "month": 1, "day": 1 }` etc. —
/// custom Codable below — so seed bundles in `Resources/ImportantDays/*.json`
/// stay human-readable.
public enum DayRule: Sendable, Equatable {
    /// Same calendar date every year (e.g. Christmas = Dec 25).
    case fixedMonthDay(month: Int, day: Int)

    /// Nth weekday of a given month (e.g. US Mother's Day = 2nd Sunday of May
    /// → `.nthWeekdayOfMonth(n: 2, weekday: 1, month: 5)`. Weekday uses
    /// Apple's 1=Sunday convention.
    case nthWeekdayOfMonth(n: Int, weekday: Int, month: Int)

    /// Last weekday of a given month (e.g. FR Mother's Day = last Sunday of
    /// May, except when it falls on Pentecost — handled approximately).
    case lastWeekdayOfMonth(weekday: Int, month: Int)

    /// One-shot date — used for anniversaries the user adds manually
    /// (wedding anniversary etc.). The year is captured but matching uses
    /// month + day so the day fires every year.
    case anniversary(year: Int, month: Int, day: Int)

    /// Resolves this rule to a concrete `Date` in the given year.
    /// Returns `nil` if components are invalid (e.g. Feb 30 → nil).
    public func resolvedDate(in year: Int, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        switch self {
        case .fixedMonthDay(let month, let day):
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            return calendar.date(from: comps)

        case .nthWeekdayOfMonth(let n, let weekday, let month):
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.weekday = weekday
            comps.weekdayOrdinal = n
            return calendar.date(from: comps)

        case .lastWeekdayOfMonth(let weekday, let month):
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.weekday = weekday
            comps.weekdayOrdinal = -1
            return calendar.date(from: comps)

        case .anniversary(_, let month, let day):
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            return calendar.date(from: comps)
        }
    }

    /// True if this rule resolves to `today`'s month + day in any year.
    public func matches(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        let target = calendar.dateComponents([.year], from: date).year ?? 2025
        guard let resolved = resolvedDate(in: target, calendar: calendar) else { return false }
        let lhs = calendar.dateComponents([.month, .day], from: date)
        let rhs = calendar.dateComponents([.month, .day], from: resolved)
        return lhs.month == rhs.month && lhs.day == rhs.day
    }

    /// Next occurrence on or after `date`. Returns nil only for impossible
    /// rules (e.g. nth-weekday combinations that don't exist).
    public func nextOccurrence(onOrAfter date: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        let year = calendar.dateComponents([.year], from: date).year ?? 2025
        if let thisYear = resolvedDate(in: year, calendar: calendar),
           calendar.startOfDay(for: thisYear) >= calendar.startOfDay(for: date) {
            return thisYear
        }
        return resolvedDate(in: year + 1, calendar: calendar)
    }
}

extension DayRule: Codable {

    private enum CodingKeys: String, CodingKey {
        case type, month, day, n, weekday, year
    }

    private enum RuleType: String, Codable {
        case fixedMonthDay
        case nthWeekdayOfMonth
        case lastWeekdayOfMonth
        case anniversary
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(RuleType.self, forKey: .type)
        switch type {
        case .fixedMonthDay:
            self = .fixedMonthDay(
                month: try c.decode(Int.self, forKey: .month),
                day: try c.decode(Int.self, forKey: .day)
            )
        case .nthWeekdayOfMonth:
            self = .nthWeekdayOfMonth(
                n: try c.decode(Int.self, forKey: .n),
                weekday: try c.decode(Int.self, forKey: .weekday),
                month: try c.decode(Int.self, forKey: .month)
            )
        case .lastWeekdayOfMonth:
            self = .lastWeekdayOfMonth(
                weekday: try c.decode(Int.self, forKey: .weekday),
                month: try c.decode(Int.self, forKey: .month)
            )
        case .anniversary:
            self = .anniversary(
                year: try c.decode(Int.self, forKey: .year),
                month: try c.decode(Int.self, forKey: .month),
                day: try c.decode(Int.self, forKey: .day)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixedMonthDay(let month, let day):
            try c.encode(RuleType.fixedMonthDay, forKey: .type)
            try c.encode(month, forKey: .month)
            try c.encode(day, forKey: .day)
        case .nthWeekdayOfMonth(let n, let weekday, let month):
            try c.encode(RuleType.nthWeekdayOfMonth, forKey: .type)
            try c.encode(n, forKey: .n)
            try c.encode(weekday, forKey: .weekday)
            try c.encode(month, forKey: .month)
        case .lastWeekdayOfMonth(let weekday, let month):
            try c.encode(RuleType.lastWeekdayOfMonth, forKey: .type)
            try c.encode(weekday, forKey: .weekday)
            try c.encode(month, forKey: .month)
        case .anniversary(let year, let month, let day):
            try c.encode(RuleType.anniversary, forKey: .type)
            try c.encode(year, forKey: .year)
            try c.encode(month, forKey: .month)
            try c.encode(day, forKey: .day)
        }
    }
}
