@testable import PersonalHygiene
@preconcurrency import XCTest

final class AustraliaAdvisoryServiceTests: XCTestCase {

    func test_emptyDestination_returnsIndex() {
        let svc = AustraliaAdvisoryService()
        let link = svc.advisory(forDestination: "")
        XCTAssertEqual(link.url, AustraliaAdvisoryService.indexURL)
        XCTAssertEqual(link.source, "smartraveller.gov.au")
    }

    func test_genericDestination_buildsSlug() {
        let svc = AustraliaAdvisoryService()
        let link = svc.advisory(forDestination: "Spain")
        XCTAssertEqual(link.url.absoluteString, "https://www.smartraveller.gov.au/destinations/spain")
    }

    func test_usaOverride() {
        XCTAssertEqual(DestinationSlug.australia("USA"), "united-states-america")
        XCTAssertEqual(DestinationSlug.australia("United Kingdom"), "united-kingdom")
    }

    func test_includedInStandardLineup() {
        let multi = MultiSourceAdvisoryService.standard()
        let links = multi.advisories(forDestination: "Spain")
        XCTAssertTrue(links.contains { $0.source == "smartraveller.gov.au" })
    }
}
