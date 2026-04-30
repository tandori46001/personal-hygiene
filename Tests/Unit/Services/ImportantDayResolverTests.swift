@preconcurrency import XCTest
import SwiftData

@testable import PersonalHygiene

@MainActor
final class ImportantDayResolverTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps)!
    }

    func test_upcoming_includesEntryToday() {
        let day = ImportantDay(
            name: "Christmas",
            dayRule: .fixedMonthDay(month: 12, day: 25)
        )
        let entries = ImportantDayResolver.upcoming(
            days: [day],
            on: date(2026, 12, 25),
            windowDays: 30,
            calendar: calendar
        )
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.daysUntil, 0)
    }

    func test_upcoming_includesWithinWindow() {
        let day = ImportantDay(
            name: "Christmas",
            dayRule: .fixedMonthDay(month: 12, day: 25)
        )
        let entries = ImportantDayResolver.upcoming(
            days: [day],
            on: date(2026, 12, 20),
            windowDays: 7,
            calendar: calendar
        )
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.daysUntil, 5)
    }

    func test_upcoming_excludesPastWindow() {
        let day = ImportantDay(
            name: "Christmas",
            dayRule: .fixedMonthDay(month: 12, day: 25)
        )
        let entries = ImportantDayResolver.upcoming(
            days: [day],
            on: date(2026, 6, 1),
            windowDays: 7,
            calendar: calendar
        )
        XCTAssertEqual(entries.count, 0)
    }

    func test_upcoming_sortedAscendingByDate() {
        let xmas = ImportantDay(name: "Christmas", dayRule: .fixedMonthDay(month: 12, day: 25))
        let nye = ImportantDay(name: "NYE", dayRule: .fixedMonthDay(month: 12, day: 31))
        let entries = ImportantDayResolver.upcoming(
            days: [nye, xmas],  // intentionally reversed input
            on: date(2026, 12, 20),
            windowDays: 30,
            calendar: calendar
        )
        XCTAssertEqual(entries.map(\.name), ["Christmas", "NYE"])
    }

    func test_upcoming_skipsRulesThatCantResolve() {
        let day = ImportantDay(
            name: "Garbage",
            dayRule: .fixedMonthDay(month: 13, day: 99)
        )
        let entries = ImportantDayResolver.upcoming(
            days: [day],
            on: date(2026, 1, 1),
            windowDays: 365,
            calendar: calendar
        )
        XCTAssertEqual(entries.count, 0)
    }
}
