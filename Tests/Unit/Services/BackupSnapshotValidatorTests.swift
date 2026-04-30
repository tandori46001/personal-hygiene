@testable import PersonalHygiene
@preconcurrency import XCTest

final class BackupSnapshotValidatorTests: XCTestCase {

    private func emptySnapshot(version: Int = 6) -> BackupSnapshot {
        BackupSnapshot(
            version: version,
            templates: [],
            completions: [],
            hydration: [],
            housekeeping: [],
            trips: []
        )
    }

    func test_validate_cleanForEmptyV6() {
        let report = BackupSnapshotValidator.validate(emptySnapshot())
        XCTAssertTrue(report.isClean)
    }

    func test_validate_errorOnVersionAboveSupported() {
        let snapshot = emptySnapshot(version: 999)
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.isFatal)
        XCTAssertTrue(report.errors.contains { $0.contains("999") })
    }

    func test_validate_errorOnDuplicateTemplateID() {
        let id = UUID()
        let template = BackupSnapshot.TemplatePayload(
            id: id, name: "A", dayType: "weekday", isActive: true, blocks: []
        )
        let dup = BackupSnapshot.TemplatePayload(
            id: id, name: "B", dayType: "weekday", isActive: false, blocks: []
        )
        let snapshot = BackupSnapshot(
            templates: [template, dup],
            completions: [], hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.errors.contains { $0.contains("Duplicate template id") })
    }

    func test_validate_errorOnUnknownDayType() {
        let template = BackupSnapshot.TemplatePayload(
            id: UUID(), name: "Mystery", dayType: "supermonday",
            isActive: true, blocks: []
        )
        let snapshot = BackupSnapshot(
            templates: [template],
            completions: [], hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.errors.contains { $0.contains("supermonday") })
    }

    func test_validate_errorOnInvalidBlockTime() {
        let block = BackupSnapshot.BlockPayload(
            id: UUID(), title: "X", category: "work",
            startMinutesFromMidnight: 9999,
            durationMinutes: 30,
            notificationLeadMinutes: 5,
            isDeepFocus: false, notes: nil
        )
        let template = BackupSnapshot.TemplatePayload(
            id: UUID(), name: "T", dayType: "weekday",
            isActive: true, blocks: [block]
        )
        let snapshot = BackupSnapshot(
            templates: [template],
            completions: [], hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.errors.contains { $0.contains("invalid start time") })
    }

    func test_validate_errorOnNonPositiveDuration() {
        let block = BackupSnapshot.BlockPayload(
            id: UUID(), title: "X", category: "work",
            startMinutesFromMidnight: 540,
            durationMinutes: 0,
            notificationLeadMinutes: 5,
            isDeepFocus: false, notes: nil
        )
        let template = BackupSnapshot.TemplatePayload(
            id: UUID(), name: "T", dayType: "weekday",
            isActive: true, blocks: [block]
        )
        let snapshot = BackupSnapshot(
            templates: [template],
            completions: [], hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.errors.contains { $0.contains("non-positive duration") })
    }

    func test_validate_warningOnDanglingCompletion() {
        let completion = BackupSnapshot.CompletionPayload(
            id: UUID(), blockID: UUID(),
            dayStart: Date(), completedAt: Date()
        )
        let snapshot = BackupSnapshot(
            templates: [], completions: [completion],
            hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertFalse(report.isFatal)
        XCTAssertTrue(report.warnings.contains { $0.contains("unknown blockID") })
    }

    func test_validate_errorOnTripStartAfterEnd() {
        let trip = BackupSnapshot.TripPayload(
            id: UUID(), name: "Reverse",
            startDate: Date().addingTimeInterval(86_400),
            endDate: Date(),
            destinationName: "X",
            destinationLatitude: nil, destinationLongitude: nil,
            milestones: []
        )
        let snapshot = BackupSnapshot(
            templates: [], completions: [],
            hydration: [], housekeeping: [], trips: [trip]
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.errors.contains { $0.contains("startDate after endDate") })
    }

    func test_validate_errorOnUnknownCategory() {
        let block = BackupSnapshot.BlockPayload(
            id: UUID(), title: "X", category: "wormhole",
            startMinutesFromMidnight: 540,
            durationMinutes: 30,
            notificationLeadMinutes: 5,
            isDeepFocus: false, notes: nil
        )
        let template = BackupSnapshot.TemplatePayload(
            id: UUID(), name: "T", dayType: "weekday",
            isActive: true, blocks: [block]
        )
        let snapshot = BackupSnapshot(
            templates: [template],
            completions: [], hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertTrue(report.errors.contains { $0.contains("wormhole") })
    }

    func test_validate_warningOnNegativeLead() {
        let block = BackupSnapshot.BlockPayload(
            id: UUID(), title: "X", category: "work",
            startMinutesFromMidnight: 540,
            durationMinutes: 30,
            notificationLeadMinutes: -5,
            isDeepFocus: false, notes: nil
        )
        let template = BackupSnapshot.TemplatePayload(
            id: UUID(), name: "T", dayType: "weekday",
            isActive: true, blocks: [block]
        )
        let snapshot = BackupSnapshot(
            templates: [template],
            completions: [], hydration: [], housekeeping: [], trips: []
        )
        let report = BackupSnapshotValidator.validate(snapshot)
        XCTAssertFalse(report.isFatal)
        XCTAssertTrue(report.warnings.contains { $0.contains("negative notificationLeadMinutes") })
    }
}
