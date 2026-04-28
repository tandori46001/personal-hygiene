@testable import PersonalHygiene
import XCTest

final class SingleTemplateBackupTests: XCTestCase {

    func test_encodeDecode_roundtripsTemplate() throws {
        let template = RoutineTemplate(
            name: "Weekday",
            dayType: .weekday,
            blocks: [
                Block(title: "Brush", category: .hygiene, startMinutesFromMidnight: 7 * 60, durationMinutes: 10),
                Block(title: "Standup", category: .work, startMinutesFromMidnight: 9 * 60, durationMinutes: 15),
            ],
            isActive: true
        )
        let data = try SingleTemplateBackup.encode(template)
        let decoded = try SingleTemplateBackup.decode(data)
        XCTAssertEqual(decoded.template.name, "Weekday")
        XCTAssertEqual(decoded.template.blocks.count, 2)
        XCTAssertEqual(decoded.version, 1)
    }

    func test_encode_neverCarriesActiveFlag() throws {
        let template = RoutineTemplate(name: "T", dayType: .weekday, blocks: [], isActive: true)
        let data = try SingleTemplateBackup.encode(template)
        let decoded = try SingleTemplateBackup.decode(data)
        XCTAssertFalse(decoded.template.isActive)
    }
}
