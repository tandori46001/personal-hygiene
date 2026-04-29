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

    // MARK: - Round 10 multi-source advisories

    func test_stateDepartment_buildsCountryAdvisorySearchURL() {
        let link = StateDepartmentAdvisoryService().advisory(forDestination: "Japan")
        XCTAssertEqual(link.source, "travel.state.gov")
        XCTAssertTrue(link.url.absoluteString.contains("travel.state.gov"))
        XCTAssertTrue(link.url.absoluteString.contains("Japan"))
    }

    func test_canada_slugifiesDestination() {
        let link = CanadaTravelAdvisoryService().advisory(forDestination: "Costa Rica")
        XCTAssertEqual(link.source, "travel.gc.ca")
        XCTAssertTrue(link.url.absoluteString.contains("travel.gc.ca/destinations/costa-rica"))
    }

    func test_uk_slugifiesDestination() {
        let link = UKFCDOAdvisoryService().advisory(forDestination: "United Kingdom")
        XCTAssertEqual(link.source, "gov.uk · FCDO")
        XCTAssertTrue(link.url.absoluteString.contains("gov.uk/foreign-travel-advice/united-kingdom"))
    }

    func test_multiSource_returnsOneEntryPerUpstream_inOrder() {
        // Round-27 follow-up: default order changed from ES-led to US-led
        // per user request. Order is configurable via `AdvisoryOrderStore`;
        // when no override is present (test environment uses fresh
        // UserDefaults), the lineup follows `AdvisoryOrderStore.defaultOrder`.
        AdvisoryOrderStore.reset()
        let svc = MultiSourceAdvisoryService.standard()
        let links = svc.advisories(forDestination: "Spain")
        XCTAssertEqual(links.map(\.source), [
            "travel.state.gov",
            "travel.gc.ca",
            "gov.uk · FCDO",
            "smartraveller.gov.au",
            "exteriores.gob.es",
        ])
    }

    func test_multiSource_singleAdvisoryFallsBackToFirstUpstream() {
        AdvisoryOrderStore.reset()
        let svc = MultiSourceAdvisoryService.standard()
        let single = svc.advisory(forDestination: "Italy")
        XCTAssertEqual(single.source, "travel.state.gov")
    }

    func test_canada_blankDestinationFallsBackToIndex() {
        let link = CanadaTravelAdvisoryService().advisory(forDestination: "")
        XCTAssertEqual(link.url, CanadaTravelAdvisoryService.indexURL)
    }

    func test_uk_blankDestinationFallsBackToIndex() {
        let link = UKFCDOAdvisoryService().advisory(forDestination: " ")
        XCTAssertEqual(link.url, UKFCDOAdvisoryService.indexURL)
    }
}
