@testable import PersonalHygiene
@preconcurrency import XCTest

final class ObservabilityHealthCheckPausedTests: XCTestCase {

    func test_paused_returnsYellow() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 0,
            widgetReloads: 5,
            observerAvailable: false,
            authStatusOK: true,
            paused: true
        )
        XCTAssertEqual(status, .yellow)
    }

    func test_pausedWithRedDrift_stillRed() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 12,
            widgetReloads: 5,
            observerAvailable: false,
            authStatusOK: true,
            paused: true
        )
        XCTAssertEqual(status, .red)
    }

    func test_pausedWithoutAuth_red() {
        let status = ObservabilityHealthCheck.status(
            routinePendingDelta: 0,
            widgetReloads: 0,
            observerAvailable: false,
            authStatusOK: false,
            paused: true
        )
        XCTAssertEqual(status, .red)
    }
}
