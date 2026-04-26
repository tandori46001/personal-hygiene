import XCTest

@testable import PersonalHygiene

final class WhatsNextDialogBuilderTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: gregorianUTC(),
            timeZone: gregorianUTC().timeZone,
            year: 2026, month: 4, day: 25, hour: hour, minute: minute
        ).date!
    }

    private func makeTemplate(blocks: [Block]) -> RoutineTemplate {
        RoutineTemplate(name: "T", dayType: .weekday, blocks: blocks, isActive: true)
    }

    func test_noTemplate_returnsNoTemplateDialog() {
        let dialog = WhatsNextDialogBuilder.build(template: nil, at: date(hour: 8, minute: 0), calendar: gregorianUTC())
        XCTAssertEqual(dialog, String(localized: "intent.whatsNext.noTemplate"))
    }

    func test_emptyTemplate_returnsNoMoreDialog() {
        let template = makeTemplate(blocks: [])
        let dialog = WhatsNextDialogBuilder.build(
            template: template,
            at: date(hour: 8, minute: 0),
            calendar: gregorianUTC()
        )
        XCTAssertEqual(dialog, String(localized: "intent.whatsNext.noMore"))
    }

    func test_currentBlock_dialogContainsTitleAndTime() {
        let block = Block(
            title: "Hygiene",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60 + 30,
            durationMinutes: 30
        )
        let dialog = WhatsNextDialogBuilder.build(
            template: makeTemplate(blocks: [block]),
            at: date(hour: 7, minute: 45),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(dialog.contains("Hygiene"))
        XCTAssertTrue(dialog.contains("07:30"))
    }

    func test_upcomingBlock_dialogContainsTitleAndTime() {
        let block = Block(
            title: "Standup",
            category: .work,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 15
        )
        let dialog = WhatsNextDialogBuilder.build(
            template: makeTemplate(blocks: [block]),
            at: date(hour: 8, minute: 0),
            calendar: gregorianUTC()
        )
        XCTAssertTrue(dialog.contains("Standup"))
        XCTAssertTrue(dialog.contains("09:00"))
    }
}
