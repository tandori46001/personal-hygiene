@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class BirthdaysViewModelTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        let cal = gregorianUTC()
        return DateComponents(calendar: cal, timeZone: cal.timeZone, year: year, month: month, day: day).date!
    }

    func test_reload_keepsEmptyWhenNotAuthorized() async {
        let service = InMemoryContactsService(
            contacts: [BirthdayContact(identifier: "1", displayName: "Sara", month: 4, day: 25, year: nil)],
            status: .notDetermined
        )
        let vm = BirthdaysViewModel(service: service, windowDays: 60, calendar: gregorianUTC())
        vm.reloadStatus()
        await vm.reload(now: date(year: 2026, month: 4, day: 25))
        XCTAssertTrue(vm.upcoming.isEmpty)
    }

    func test_reload_populatesUpcomingAfterAuth() async {
        let service = InMemoryContactsService(
            contacts: [BirthdayContact(identifier: "1", displayName: "Sara", month: 4, day: 25, year: nil)],
            status: .authorized
        )
        let vm = BirthdaysViewModel(service: service, windowDays: 60, calendar: gregorianUTC())
        vm.reloadStatus()
        await vm.reload(now: date(year: 2026, month: 4, day: 25))
        XCTAssertEqual(vm.upcoming.count, 1)
        XCTAssertEqual(vm.upcoming.first?.daysUntil, 0)
    }

    func test_requestAccess_flipsStatusAndReloads() async {
        let service = InMemoryContactsService(
            contacts: [BirthdayContact(identifier: "1", displayName: "Sara", month: 4, day: 25, year: nil)],
            status: .notDetermined,
            grantOnRequest: true
        )
        let vm = BirthdaysViewModel(service: service, windowDays: 60, calendar: gregorianUTC())
        await vm.requestAccess()
        XCTAssertEqual(vm.status, .authorized)
    }
}
