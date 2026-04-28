@testable import PersonalHygiene
import XCTest

final class BlockCSVImporterTests: XCTestCase {

    func test_parse_acceptsValidCSV() {
        let csv = """
        title,category,startMinutes,durationMinutes
        Standup,work,540,15
        Brush,hygiene,420,10
        """
        let result = BlockCSVImporter.parse(csv)
        XCTAssertEqual(result.blocks.count, 2)
        XCTAssertEqual(result.blocks.first?.title, "Standup")
        XCTAssertEqual(result.blocks.first?.category, .work)
        XCTAssertEqual(result.blocks.first?.startMinutesFromMidnight, 540)
    }

    func test_parse_unknownCategory_fallsBackToHygiene_withWarning() {
        let csv = """
        title,category,startMinutes,durationMinutes
        Coffee,nonsense,420,10
        """
        let result = BlockCSVImporter.parse(csv)
        XCTAssertEqual(result.blocks.first?.category, .hygiene)
        XCTAssertTrue(result.warnings.contains { $0.contains("nonsense") })
    }

    func test_parse_skipsRowsWithMissingColumnsOrInvalidNumbers() {
        let csv = """
        title,category,startMinutes,durationMinutes
        ,work,420,10
        Standup,work,abc,10
        Standup,work,420,0
        Standup,work,420,30
        """
        let result = BlockCSVImporter.parse(csv)
        XCTAssertEqual(result.blocks.count, 1, "only the last well-formed row survives")
        // At least the three bad rows produce warnings; parser may emit
        // additional context lines in the future, so we don't pin to an
        // exact count.
        XCTAssertGreaterThanOrEqual(result.warnings.count, 3)
    }

    func test_parse_emptyInput_emitsOnlyEmptyWarning() {
        let result = BlockCSVImporter.parse("")
        XCTAssertTrue(result.blocks.isEmpty)
        XCTAssertEqual(result.warnings, ["empty input"])
    }

    func test_parse_missingHeader_treatsFirstRowAsData() {
        let csv = """
        Standup,work,540,15
        """
        let result = BlockCSVImporter.parse(csv)
        XCTAssertEqual(result.blocks.count, 1)
        XCTAssertTrue(result.warnings.first?.contains("header") ?? false)
    }
}
