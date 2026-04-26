import XCTest

@testable import PersonalHygiene

final class TravelAdvisoryServiceTests: XCTestCase {

    func test_advisory_includesDestinationAsQueryParameter() {
        let service = ExterioresAdvisoryService()
        let link = service.advisory(forDestination: "Mauritius")

        XCTAssertEqual(link.source, "exteriores.gob.es")
        XCTAssertEqual(link.displayName, "Mauritius")
        XCTAssertTrue(link.url.absoluteString.contains("q=Mauritius"))
    }

    func test_advisory_blankDestinationFallsBackToIndex() {
        let service = ExterioresAdvisoryService()
        let link = service.advisory(forDestination: "  ")

        XCTAssertEqual(link.url, ExterioresAdvisoryService.indexURL)
    }

    func test_advisory_urlEncodesSpecialCharacters() {
        let service = ExterioresAdvisoryService()
        let link = service.advisory(forDestination: "Côte d'Ivoire")

        XCTAssertTrue(link.url.absoluteString.contains("q="))
        XCTAssertFalse(link.url.absoluteString.contains(" "))
    }
}
