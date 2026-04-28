@testable import PersonalHygiene
import XCTest

final class TripNotesCSVImporterTests: XCTestCase {

    func test_parse_emitsMarkdownBulletPerRow() {
        let csv = """
        day,note
        Monday,Pack passport
        Tuesday,Confirm hotel
        """
        let result = TripNotesCSVImporter.parse(csv)
        XCTAssertEqual(result.warnings, [])
        XCTAssertTrue(result.markdown.contains("- **Monday** — Pack passport"))
        XCTAssertTrue(result.markdown.contains("- **Tuesday** — Confirm hotel"))
    }

    func test_parse_skipsRowsWithEmptyDayOrNote() {
        let csv = """
        day,note
        ,empty day
        Tuesday,
        Wednesday,Buy snacks
        """
        let result = TripNotesCSVImporter.parse(csv)
        XCTAssertTrue(result.markdown.contains("Wednesday"))
        XCTAssertEqual(result.warnings.count, 2)
    }

    func test_parse_emptyInput_emitsWarning() {
        let result = TripNotesCSVImporter.parse("")
        XCTAssertTrue(result.markdown.isEmpty)
        XCTAssertEqual(result.warnings, ["empty input"])
    }
}
