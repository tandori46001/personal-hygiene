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

    // MARK: - 7-day window edges (round 6 slice 11)

    func test_dailySummaries_emptyWindowReturnsEmpty() {
        let summaries = MedicationCompliance.dailySummaries(
            from: [],
            between: date(year: 2026, month: 4, day: 19, hour: 0),
            and: date(year: 2026, month: 4, day: 25, hour: 23),
            calendar: gregorianUTC()
        )
        // No logs → no summaries (we don't synthesize empty days).
        XCTAssertTrue(summaries.isEmpty)
    }

    func test_overallAdherence_allTakenAcross7Days() {
        var logs: [MedicationDoseLog] = []
        for offset in 0..<7 {
            logs.append(
                MedicationDoseLog(
                    conceptIdentifier: "c1",
                    scheduledAt: date(year: 2026, month: 4, day: 19 + offset),
                    status: .taken
                )
            )
        }
        let rate = MedicationCompliance.overallAdherence(
            from: logs,
            between: date(year: 2026, month: 4, day: 19),
            and: date(year: 2026, month: 4, day: 25, hour: 23)
        )
        XCTAssertEqual(rate, 1.0, accuracy: 0.001)
    }

    private func log(day: Int, hour: Int = 8, status: MedicationDoseLog.Status) -> MedicationDoseLog {
        MedicationDoseLog(
            conceptIdentifier: "c1",
            scheduledAt: date(year: 2026, month: 4, day: day, hour: hour),
            status: status
        )
    }

    func test_overallAdherence_partialOverWeek_isCorrectRatio() {
        let logs = [
            log(day: 19, status: .taken),
            log(day: 20, status: .taken),
            log(day: 21, status: .missed),
            log(day: 22, status: .skipped),
            log(day: 23, status: .taken),
        ]
        let rate = MedicationCompliance.overallAdherence(
            from: logs,
            between: date(year: 2026, month: 4, day: 19),
            and: date(year: 2026, month: 4, day: 25, hour: 23)
        )
        XCTAssertEqual(rate, 3.0 / 5.0, accuracy: 0.001)
    }

    func test_dailySummaries_multipleDosesPerDayAccumulate() {
        let cal = gregorianUTC()
        let logs = [
            log(day: 25, hour: 8, status: .taken),
            log(day: 25, hour: 14, status: .taken),
            log(day: 25, hour: 22, status: .missed),
        ]
        let summaries = MedicationCompliance.dailySummaries(
            from: logs,
            between: date(year: 2026, month: 4, day: 25),
            and: date(year: 2026, month: 4, day: 25, hour: 23),
            calendar: cal
        )
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].scheduledCount, 3)
        XCTAssertEqual(summaries[0].takenCount, 2)
    }
}
