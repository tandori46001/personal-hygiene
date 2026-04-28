@testable import PersonalHygiene
import XCTest

final class BackupAutoFrequencySuggestionTests: XCTestCase {

    private func date(_ daysFromBase: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28
        ).date!
        return cal.date(byAdding: .day, value: daysFromBase, to: base)!
    }

    func test_shouldSurface_trueWhenNeverBackedUp() {
        XCTAssertTrue(BackupAutoFrequencySuggestion.shouldSurfaceBanner(
            lastBackupAt: nil,
            now: date(0)
        ))
    }

    func test_shouldSurface_falseWhenWithinRecommendation() {
        XCTAssertFalse(BackupAutoFrequencySuggestion.shouldSurfaceBanner(
            lastBackupAt: date(-3),
            recommendedDays: 7,
            now: date(0)
        ))
    }

    func test_shouldSurface_trueAtBoundary() {
        XCTAssertTrue(BackupAutoFrequencySuggestion.shouldSurfaceBanner(
            lastBackupAt: date(-7),
            recommendedDays: 7,
            now: date(0)
        ))
    }

    func test_daysSinceLastBackup_nilWhenNever() {
        XCTAssertNil(BackupAutoFrequencySuggestion.daysSinceLastBackup(
            lastBackupAt: nil,
            now: date(0)
        ))
    }

    func test_daysSinceLastBackup_returnsGap() {
        XCTAssertEqual(
            BackupAutoFrequencySuggestion.daysSinceLastBackup(
                lastBackupAt: date(-5),
                now: date(0)
            ),
            5
        )
    }
}
