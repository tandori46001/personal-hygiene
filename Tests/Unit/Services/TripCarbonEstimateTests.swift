@testable import PersonalHygiene
import XCTest

final class TripCarbonEstimateTests: XCTestCase {

    func test_distance_madridToTokyoApproximately10700km() {
        // Madrid 40.4168, -3.7038 · Tokyo 35.6762, 139.6503
        let dist = TripCarbonEstimate.distanceKm(
            fromLat: 40.4168,
            fromLon: -3.7038,
            toLat: 35.6762,
            toLon: 139.6503
        )
        XCTAssertEqual(dist, 10_770, accuracy: 50)
    }

    func test_distance_samePoint_zero() {
        let dist = TripCarbonEstimate.distanceKm(
            fromLat: 40, fromLon: -3,
            toLat: 40, toLon: -3
        )
        XCTAssertEqual(dist, 0, accuracy: 0.001)
    }

    func test_roundTripKgCO2_madridTokyo() {
        let dist = TripCarbonEstimate.distanceKm(
            fromLat: 40.4168,
            fromLon: -3.7038,
            toLat: 35.6762,
            toLon: 139.6503
        )
        let kg = TripCarbonEstimate.roundTripKgCO2(distanceKm: dist)
        // Round-trip ~21540km × 0.255 = ~5500kg
        XCTAssertEqual(kg, 5_500, accuracy: 100)
    }

    func test_roundTripKgCO2_negativeDistanceClamped() {
        XCTAssertEqual(TripCarbonEstimate.roundTripKgCO2(distanceKm: -100), 0)
    }
}
