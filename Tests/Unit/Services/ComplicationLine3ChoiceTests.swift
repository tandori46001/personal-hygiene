@testable import PersonalHygiene
import XCTest

final class ComplicationLine3ChoiceTests: XCTestCase {

    private let suite = "complicationChoice-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_current_defaultsToDayCompletion() {
        XCTAssertEqual(
            ComplicationLine3Choice.current(in: defaults),
            .dayCompletion
        )
    }

    func test_setAndRead_roundTrips() {
        ComplicationLine3Choice.set(.mood, in: defaults)
        XCTAssertEqual(ComplicationLine3Choice.current(in: defaults), .mood)
        ComplicationLine3Choice.set(.medicationStreak, in: defaults)
        XCTAssertEqual(ComplicationLine3Choice.current(in: defaults), .medicationStreak)
    }

    func test_allCases_includesThree() {
        XCTAssertEqual(ComplicationLine3Choice.Choice.allCases.count, 3)
    }
}
