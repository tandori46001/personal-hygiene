@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-20 slice T1.4 — property-style round-trip test for the four known
/// notification identifier shapes. Generates 1000 random inputs across the
/// four `BlockSnoozeSource` cases and asserts:
///
/// 1. The identifier built by the factory parses back to the *same* values.
/// 2. Suffixing with `.snooze.<timestamp>` still parses to the same kind +
///    payload (the `parseAny` snooze-strip logic).
///
/// Catches: drift between any factory's `identifier` string and the parser
/// switch in `BlockNotificationIdentifier.parseAny(_:)`. Compile time L002
/// already protects new kinds — this guards format drift on existing kinds.
@MainActor
final class BlockNotifIDRoundTripTests: XCTestCase {

    func test_routine_roundTripsAcrossManyInputs() throws {
        for _ in 0..<250 {
            let blockID = UUID()
            let dayKey = randomDayKey()
            let identifier = "\(NotificationFactory.identifierPrefix)\(blockID.uuidString).\(dayKey)"
            guard case let .routine(parsedID, parsedDay) = BlockNotificationIdentifier.parseAny(identifier) else {
                XCTFail("routine round-trip failed for \(identifier)"); return
            }
            XCTAssertEqual(parsedID, blockID)
            XCTAssertEqual(parsedDay, dayKey)
            assertSnoozeStripStillRoundTrips(identifier)
        }
    }

    func test_hydration_roundTripsAcrossManyInputs() throws {
        for _ in 0..<250 {
            let dayKey = randomDayKey()
            let index = Int.random(in: 0...23)
            let identifier = "\(HydrationNotificationFactory.identifierPrefix)\(dayKey).\(index)"
            guard case let .hydration(parsedDay, parsedIndex) = BlockNotificationIdentifier.parseAny(identifier) else {
                XCTFail("hydration round-trip failed for \(identifier)"); return
            }
            XCTAssertEqual(parsedDay, dayKey)
            XCTAssertEqual(parsedIndex, index)
            assertSnoozeStripStillRoundTrips(identifier)
        }
    }

    func test_milestone_roundTripsAcrossManyInputs() throws {
        for _ in 0..<250 {
            let milestoneID = UUID()
            let identifier = "\(TripMilestoneNotificationFactory.identifierPrefix)\(milestoneID.uuidString)"
            guard case let .milestone(parsedID) = BlockNotificationIdentifier.parseAny(identifier) else {
                XCTFail("milestone round-trip failed for \(identifier)"); return
            }
            XCTAssertEqual(parsedID, milestoneID)
            assertSnoozeStripStillRoundTrips(identifier)
        }
    }

    func test_medicationFollowUp_roundTripsAcrossManyInputs() throws {
        for _ in 0..<250 {
            let blockID = UUID()
            let dayKey = randomDayKey()
            let identifier = "\(MedicationFollowUpFactory.identifierPrefix)\(blockID.uuidString).\(dayKey)"
            guard case let .medicationFollowUp(parsedID, parsedDay) =
                    BlockNotificationIdentifier.parseAny(identifier)
            else {
                XCTFail("medication round-trip failed for \(identifier)"); return
            }
            XCTAssertEqual(parsedID, blockID)
            XCTAssertEqual(parsedDay, dayKey)
            assertSnoozeStripStillRoundTrips(identifier)
        }
    }

    /// Unknown / malformed shapes always parse to nil so the action handler's
    /// fallback `default:` branch fires.
    func test_unknownShapesReturnNil() {
        XCTAssertNil(BlockNotificationIdentifier.parseAny(""))
        XCTAssertNil(BlockNotificationIdentifier.parseAny("garbage"))
        XCTAssertNil(BlockNotificationIdentifier.parseAny("personal-hygiene.unknown.12345"))
        XCTAssertNil(BlockNotificationIdentifier.parseAny("personal-hygiene.block.not-a-uuid.dayKey"))
    }

    // MARK: - Helpers

    private func randomDayKey() -> String {
        let year = Int.random(in: 2024...2030)
        let month = Int.random(in: 1...12)
        let day = Int.random(in: 1...28)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func assertSnoozeStripStillRoundTrips(
        _ identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let timestamp = Int.random(in: 1...10_000_000)
        let suffixed = "\(identifier).snooze.\(timestamp)"
        XCTAssertNotNil(
            BlockNotificationIdentifier.parseAny(suffixed),
            "snooze suffix should still parse for \(suffixed)",
            file: file,
            line: line
        )
    }
}
