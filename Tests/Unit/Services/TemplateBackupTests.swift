@testable import PersonalHygiene
import XCTest

final class TemplateBackupTests: XCTestCase {

    func test_encodeDecodeRoundtrip() throws {
        let block = Block(
            title: "Morning routine",
            category: .hygiene,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 30,
            notes: "Brush teeth, shower",
            notificationLeadMinutes: 10,
            isDeepFocus: false
        )
        let template = RoutineTemplate(
            name: "Weekday",
            dayType: .weekday,
            blocks: [block],
            isActive: false
        )
        let data = try TemplateBackup.encode(template)
        let payload = try TemplateBackup.decode(data)
        XCTAssertEqual(payload.template.name, "Weekday")
        XCTAssertEqual(payload.template.blocks.count, 1)
        XCTAssertEqual(payload.template.blocks[0].title, "Morning routine")
        XCTAssertEqual(payload.template.blocks[0].notes, "Brush teeth, shower")
    }

    func test_makeTemplate_handlesUnknownEnum() throws {
        let payload = TemplateBackup.Payload(
            template: TemplateBackup.TemplateDTO(
                name: "Imported",
                dayType: "weekday",
                blocks: [
                    TemplateBackup.BlockDTO(
                        title: "Mystery",
                        category: "not-a-real-category",
                        startMinutesFromMidnight: 8 * 60,
                        durationMinutes: 15,
                        notes: nil,
                        notificationLeadMinutes: 15,
                        isDeepFocus: false,
                        medicationConceptIdentifier: nil
                    )
                ]
            )
        )
        let template = TemplateBackup.makeTemplate(from: payload)
        XCTAssertEqual(template.blocks.first?.category, .work)
    }
}
