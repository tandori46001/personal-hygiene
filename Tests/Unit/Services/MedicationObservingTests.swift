@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class MedicationObservingTests: XCTestCase {

    func test_mock_startRegistersHandlerAndIncrementsCount() {
        let observer = MockMedicationObserver()
        XCTAssertEqual(observer.activeHandlerCount, 0)

        observer.start(for: "rxnorm:1234") {}

        XCTAssertEqual(observer.activeHandlerCount, 1)
        XCTAssertEqual(observer.startedIdentifiers, ["rxnorm:1234"])
    }

    func test_mock_simulateChangeFiresRegisteredHandler() {
        let observer = MockMedicationObserver()
        var fired = 0
        observer.start(for: "rxnorm:9876") {
            fired += 1
        }

        observer.simulateChange(for: "rxnorm:9876")
        observer.simulateChange(for: "rxnorm:9876")

        XCTAssertEqual(fired, 2)
    }

    func test_mock_duplicateStartReplacesHandler() {
        let observer = MockMedicationObserver()
        var firstFired = 0
        var secondFired = 0
        observer.start(for: "rxnorm:1") { firstFired += 1 }
        observer.start(for: "rxnorm:1") { secondFired += 1 }

        observer.simulateChange(for: "rxnorm:1")

        // Last-writer-wins per protocol contract.
        XCTAssertEqual(firstFired, 0)
        XCTAssertEqual(secondFired, 1)
        // Both starts are still recorded for diagnostics.
        XCTAssertEqual(observer.startedIdentifiers, ["rxnorm:1", "rxnorm:1"])
        XCTAssertEqual(observer.activeHandlerCount, 1)
    }

    func test_mock_stopRemovesHandlerAndRecords() {
        let observer = MockMedicationObserver()
        var fired = 0
        observer.start(for: "rxnorm:42") { fired += 1 }

        observer.stop(for: "rxnorm:42")
        observer.simulateChange(for: "rxnorm:42")

        XCTAssertEqual(fired, 0)
        XCTAssertEqual(observer.activeHandlerCount, 0)
        XCTAssertEqual(observer.stoppedIdentifiers, ["rxnorm:42"])
    }

    func test_mock_stopOnUnregisteredIdentifierIsNoOp() {
        let observer = MockMedicationObserver()
        observer.stop(for: "rxnorm:does-not-exist")
        XCTAssertTrue(observer.stoppedIdentifiers.isEmpty)
    }

    func test_mock_stopAllClearsHandlersAndRecordsEach() {
        let observer = MockMedicationObserver()
        observer.start(for: "a") {}
        observer.start(for: "b") {}
        observer.start(for: "c") {}
        XCTAssertEqual(observer.activeHandlerCount, 3)

        observer.stopAll()

        XCTAssertEqual(observer.activeHandlerCount, 0)
        XCTAssertEqual(Set(observer.stoppedIdentifiers), Set(["a", "b", "c"]))
    }

    // MARK: - Production gating

    func test_productionService_isUnavailableUntilEntitlementLands() {
        let service = MedicationObserverService()
        XCTAssertFalse(service.isAvailable)
    }

    func test_productionService_startWhenUnavailableDoesNotFireCallback() {
        let service = MedicationObserverService()
        var fired = 0
        service.start(for: "rxnorm:1") { fired += 1 }
        // Without HKObserverQuery wiring there is nothing to fire the
        // callback; the contract is "no signal until isAvailable == true".
        XCTAssertEqual(fired, 0)
    }
}
