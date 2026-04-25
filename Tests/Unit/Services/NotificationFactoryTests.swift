import XCTest

@testable import PersonalHygiene

final class NotificationFactoryTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour, minute: minute
        ).date!
    }

    func test_notifications_emitsTriggerAtBlockStartMinusLead() {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30,
            notificationLeadMinutes: 15
        )
        let day = date(year: 2026, month: 4, day: 25)

        let result = NotificationFactory.notifications(for: [block], on: day, calendar: gregorianUTC())

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Aseo")
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 6, minute: 45))
        XCTAssertFalse(result[0].isCritical)
    }

    func test_notifications_skipsBlocksWhereLeadCrossesMidnight() {
        let block = Block(
            title: "Early",
            category: .hygiene,
            startMinutesFromMidnight: 5,
            durationMinutes: 30,
            notificationLeadMinutes: 15
        )

        let result = NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )

        XCTAssertTrue(result.isEmpty)
    }

    func test_notifications_marksMedicationAsCritical() {
        let block = Block(
            title: "Pastilla",
            category: .medication,
            startMinutesFromMidnight: 8 * 60,
            durationMinutes: 5,
            notificationLeadMinutes: 5
        )

        let result = NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            calendar: gregorianUTC()
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result[0].isCritical)
    }

    func test_notifications_identifierIsStableForBlockAndDay() {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )
        let day = date(year: 2026, month: 4, day: 25)

        let first = NotificationFactory.notifications(for: [block], on: day, calendar: gregorianUTC())
        let second = NotificationFactory.notifications(for: [block], on: day, calendar: gregorianUTC())

        XCTAssertEqual(first[0].identifier, second[0].identifier)
        XCTAssertTrue(first[0].identifier.hasPrefix(NotificationFactory.identifierPrefix))
        XCTAssertTrue(first[0].identifier.contains("2026-04-25"))
    }

    func test_notifications_identifierDiffersAcrossDays() {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30
        )

        let day1 = NotificationFactory.notifications(
            for: [block], on: date(year: 2026, month: 4, day: 25), calendar: gregorianUTC()
        )
        let day2 = NotificationFactory.notifications(
            for: [block], on: date(year: 2026, month: 4, day: 26), calendar: gregorianUTC()
        )

        XCTAssertNotEqual(day1[0].identifier, day2[0].identifier)
    }

    // MARK: - Travel-time path

    private let home = BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Home")
    private let clinic = BlockLocation(latitude: 40.4500, longitude: -3.6800, displayName: "Clinic")

    func test_async_addsTravelTimeWhenBlockHasLocationAndOriginConfigured() async {
        let block = Block(
            title: "Dentist",
            category: .medical,
            startMinutesFromMidnight: 10 * 60,
            durationMinutes: 60,
            notificationLeadMinutes: 15,
            location: clinic
        )
        let pair = StaticTravelTimeService.RoutePair(origin: home, destination: clinic)
        let service = StaticTravelTimeService(overrides: [pair: 25 * 60])  // 25 min

        let result = await NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            origin: home,
            travelTimeService: service,
            calendar: gregorianUTC()
        )

        XCTAssertEqual(result.count, 1)
        // Effective lead = 15 (static) + 25 (travel) = 40 min before 10:00 → 09:20.
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 9, minute: 20))
    }

    func test_async_roundsTravelTimeUpToTheNextMinute() async {
        let block = Block(
            title: "Dentist",
            category: .medical,
            startMinutesFromMidnight: 10 * 60,
            durationMinutes: 60,
            notificationLeadMinutes: 0,
            location: clinic
        )
        let pair = StaticTravelTimeService.RoutePair(origin: home, destination: clinic)
        let service = StaticTravelTimeService(overrides: [pair: 61])  // 1 min 1 sec

        let result = await NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            origin: home,
            travelTimeService: service,
            calendar: gregorianUTC()
        )

        // 61s ceil → 2 min, lead = 0 + 2 = 2 min before 10:00 → 09:58.
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 9, minute: 58))
    }

    func test_async_fallsBackToStaticLeadWhenBlockHasNoLocation() async {
        let block = Block(
            title: "Aseo",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30,
            notificationLeadMinutes: 15
        )
        let service = StaticTravelTimeService(defaultTravelTime: 99 * 60)

        let result = await NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            origin: home,
            travelTimeService: service,
            calendar: gregorianUTC()
        )

        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 6, minute: 45))
    }

    func test_async_fallsBackToStaticLeadWhenServiceThrows() async {
        struct ThrowingService: TravelTimeService {
            func estimatedTravelTime(
                from _: BlockLocation,
                to _: BlockLocation,
                mode _: TravelMode
            ) async throws -> TimeInterval {
                throw TravelTimeError.noRouteFound
            }
        }
        let block = Block(
            title: "Dentist",
            category: .medical,
            startMinutesFromMidnight: 10 * 60,
            durationMinutes: 60,
            notificationLeadMinutes: 15,
            location: clinic
        )

        let result = await NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            origin: home,
            travelTimeService: ThrowingService(),
            calendar: gregorianUTC()
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].triggerDate, date(year: 2026, month: 4, day: 25, hour: 9, minute: 45))
    }

    func test_async_skipsBlockWhenTravelTimeWouldCrossMidnight() async {
        let block = Block(
            title: "Early",
            category: .medical,
            startMinutesFromMidnight: 30,
            durationMinutes: 30,
            notificationLeadMinutes: 5,
            location: clinic
        )
        let pair = StaticTravelTimeService.RoutePair(origin: home, destination: clinic)
        let service = StaticTravelTimeService(overrides: [pair: 60 * 60])  // 60 min — pushes trigger before 00:00

        let result = await NotificationFactory.notifications(
            for: [block],
            on: date(year: 2026, month: 4, day: 25),
            origin: home,
            travelTimeService: service,
            calendar: gregorianUTC()
        )

        XCTAssertTrue(result.isEmpty)
    }
}
