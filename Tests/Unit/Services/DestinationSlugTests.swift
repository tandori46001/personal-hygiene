@preconcurrency import XCTest

@testable import PersonalHygiene

final class DestinationSlugTests: XCTestCase {

    func test_auto_lowercasesAndHyphenates() {
        XCTAssertEqual(DestinationSlug.auto("Costa Rica"), "costa-rica")
        // CharacterSet.alphanumerics keeps `ô` (it's a Unicode letter), so the
        // accent survives the auto-slug path. The travel.gc.ca + gov.uk
        // overrides handle this case explicitly when needed.
        XCTAssertEqual(DestinationSlug.auto("Côte d'Ivoire"), "côte-d-ivoire")
        XCTAssertEqual(DestinationSlug.auto("United Arab Emirates"), "united-arab-emirates")
    }

    func test_auto_emptyReturnsEmpty() {
        XCTAssertEqual(DestinationSlug.auto(""), "")
        XCTAssertEqual(DestinationSlug.auto("   "), "")
    }

    func test_ukFCDO_overridesUSAVariants() {
        XCTAssertEqual(DestinationSlug.ukFCDO("USA"), "the-united-states-of-america")
        XCTAssertEqual(DestinationSlug.ukFCDO("us"), "the-united-states-of-america")
        XCTAssertEqual(DestinationSlug.ukFCDO("United States"), "the-united-states-of-america")
        XCTAssertEqual(DestinationSlug.ukFCDO("America"), "the-united-states-of-america")
    }

    func test_ukFCDO_overridesKoreaVariants() {
        XCTAssertEqual(DestinationSlug.ukFCDO("Korea"), "south-korea")
        XCTAssertEqual(DestinationSlug.ukFCDO("South Korea"), "south-korea")
        XCTAssertEqual(DestinationSlug.ukFCDO("North Korea"), "north-korea")
    }

    func test_ukFCDO_fallsBackToAutoSlug() {
        XCTAssertEqual(DestinationSlug.ukFCDO("Spain"), "spain")
        XCTAssertEqual(DestinationSlug.ukFCDO("Costa Rica"), "costa-rica")
    }

    func test_canada_overridesUSAVariants() {
        XCTAssertEqual(DestinationSlug.canada("USA"), "united-states")
        XCTAssertEqual(DestinationSlug.canada("us"), "united-states")
        XCTAssertEqual(DestinationSlug.canada("America"), "united-states")
    }

    func test_canada_fallsBackToAutoSlug() {
        XCTAssertEqual(DestinationSlug.canada("Japan"), "japan")
        XCTAssertEqual(DestinationSlug.canada("Costa Rica"), "costa-rica")
    }
}
