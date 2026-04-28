@testable import PersonalHygiene
import XCTest

final class BirthdayGiftIdeaCSVExporterTests: XCTestCase {

    func test_render_emitsHeaderAndOneRowPerEntrySorted() {
        let csv = BirthdayGiftIdeaCSVExporter.render(dictionary: [
            "id-2": "Book",
            "id-1": "Watch",
        ])
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines, ["contactID,idea", "id-1,Watch", "id-2,Book"])
    }

    func test_render_quotesIdeasContainingCommas() {
        let csv = BirthdayGiftIdeaCSVExporter.render(dictionary: [
            "id-1": "Book, candle"
        ])
        XCTAssertTrue(csv.contains("\"Book, candle\""))
    }

    func test_render_quotesIdeasContainingQuotes() {
        let csv = BirthdayGiftIdeaCSVExporter.render(dictionary: [
            "id-1": "He said \"yes\""
        ])
        XCTAssertTrue(csv.contains("\"He said \"\"yes\"\"\""))
    }

    func test_render_emptyDictionary_emitsHeaderOnly() {
        let csv = BirthdayGiftIdeaCSVExporter.render(dictionary: [:])
        XCTAssertEqual(csv, "contactID,idea")
    }
}
