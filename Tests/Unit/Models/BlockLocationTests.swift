@preconcurrency import XCTest

@testable import PersonalHygiene

final class BlockLocationTests: XCTestCase {

    func test_coordinate_returnsLatLonAsCLLocationCoordinate2D() {
        let location = BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Madrid")
        XCTAssertEqual(location.coordinate.latitude, 40.4168, accuracy: 1e-9)
        XCTAssertEqual(location.coordinate.longitude, -3.7038, accuracy: 1e-9)
    }

    func test_isValid_acceptsRealCoordinates() {
        let madrid = BlockLocation(latitude: 40.4168, longitude: -3.7038)
        XCTAssertTrue(madrid.isValid)
    }

    func test_isValid_rejectsOutOfRangeCoordinates() {
        let bogus = BlockLocation(latitude: 200, longitude: -500)
        XCTAssertFalse(bogus.isValid)
    }

    func test_blockLocation_isCodableRoundtrip() throws {
        let original = BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Madrid")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BlockLocation.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
