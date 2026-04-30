@testable import PersonalHygiene
@preconcurrency import XCTest

final class ObservabilityHealthCheckTests: XCTestCase {

    func test_green_whenAllOK() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 0,
            widgetReloads: 3,
            observerAvailable: false,
            authStatusOK: true
        )
        XCTAssertEqual(status, .green)
    }

    func test_yellow_whenSmallDrift() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 2,
            widgetReloads: 3,
            observerAvailable: false,
            authStatusOK: true
        )
        XCTAssertEqual(status, .yellow)
    }

    func test_red_whenLargeDrift() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 12,
            widgetReloads: 3,
            observerAvailable: false,
            authStatusOK: true
        )
        XCTAssertEqual(status, .red)
    }

    func test_red_whenAuthMissing() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 0,
            widgetReloads: 3,
            observerAvailable: false,
            authStatusOK: false
        )
        XCTAssertEqual(status, .red)
    }

    func test_yellow_whenObserverAvailableButNoReloads() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 0,
            widgetReloads: 0,
            observerAvailable: true,
            authStatusOK: true
        )
        XCTAssertEqual(status, .yellow)
    }
}
