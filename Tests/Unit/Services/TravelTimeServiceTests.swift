import XCTest

@testable import PersonalHygiene

final class TravelTimeServiceTests: XCTestCase {

    private let madrid = BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Madrid")
    private let toledo = BlockLocation(latitude: 39.8628, longitude: -4.0273, displayName: "Toledo")

    func test_static_returnsDefaultWhenNoOverride() async throws {
        let service = StaticTravelTimeService(defaultTravelTime: 600)
        let actual = try await service.estimatedTravelTime(from: madrid, to: toledo, mode: .automobile)
        XCTAssertEqual(actual, 600)
    }

    func test_static_returnsOverrideWhenPairMatches() async throws {
        let pair = StaticTravelTimeService.RoutePair(origin: madrid, destination: toledo)
        let service = StaticTravelTimeService(
            defaultTravelTime: 0,
            overrides: [pair: 1500]
        )
        let actual = try await service.estimatedTravelTime(from: madrid, to: toledo, mode: .automobile)
        XCTAssertEqual(actual, 1500)
    }

    func test_static_overrideIsDirectional() async throws {
        let pair = StaticTravelTimeService.RoutePair(origin: madrid, destination: toledo)
        let service = StaticTravelTimeService(
            defaultTravelTime: 0,
            overrides: [pair: 1500]
        )
        let reverse = try await service.estimatedTravelTime(from: toledo, to: madrid, mode: .automobile)
        XCTAssertEqual(reverse, 0, "Reverse pair must not match the override")
    }
}
