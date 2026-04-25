import XCTest

@testable import PersonalHygiene

final class MedicationComplianceTests: XCTestCase {

    private func gregorianUTC() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 8) -> Date {
        let cal = gregorianUTC()
        return DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: year, month: month, day: day, hour: hour
        ).date!
    }

    func test_dailySummaries_bucketsLogsByStartOfDay() {
        let logs = [
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 25), status: .taken),
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 25, hour: 20), status: .taken),
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 26), status: .skipped),
        ]

        let summaries = MedicationCompliance.dailySummaries(
            from: logs,
            between: date(year: 2026, month: 4, day: 25, hour: 0),
            and: date(year: 2026, month: 4, day: 26, hour: 23),
            calendar: gregorianUTC()
        )

        XCTAssertEqual(summaries.count, 2)
        XCTAssertEqual(summaries[0].scheduledCount, 2)
        XCTAssertEqual(summaries[0].takenCount, 2)
        XCTAssertEqual(summaries[0].rate, 1.0, accuracy: 0.001)
        XCTAssertEqual(summaries[1].scheduledCount, 1)
        XCTAssertEqual(summaries[1].takenCount, 0)
        XCTAssertEqual(summaries[1].rate, 0.0, accuracy: 0.001)
    }

    func test_overallAdherence_returnsOneWhenNoLogs() {
        let result = MedicationCompliance.overallAdherence(
            from: [],
            between: date(year: 2026, month: 4, day: 25),
            and: date(year: 2026, month: 4, day: 26)
        )
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func test_overallAdherence_computesTakenRatio() {
        let logs = [
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 25), status: .taken),
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 25, hour: 13), status: .skipped),
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 25, hour: 20), status: .missed),
        ]

        let result = MedicationCompliance.overallAdherence(
            from: logs,
            between: date(year: 2026, month: 4, day: 25, hour: 0),
            and: date(year: 2026, month: 4, day: 25, hour: 23)
        )

        XCTAssertEqual(result, 1.0 / 3.0, accuracy: 0.001)
    }

    func test_overallAdherence_excludesLogsOutsideRange() {
        let logs = [
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 25), status: .taken),
            MedicationDoseLog(
                conceptIdentifier: "c1", scheduledAt: date(year: 2026, month: 4, day: 30), status: .skipped),
        ]

        let result = MedicationCompliance.overallAdherence(
            from: logs,
            between: date(year: 2026, month: 4, day: 25, hour: 0),
            and: date(year: 2026, month: 4, day: 25, hour: 23)
        )

        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }
}
