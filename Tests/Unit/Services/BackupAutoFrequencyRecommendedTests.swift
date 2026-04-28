@testable import PersonalHygiene
import XCTest

final class BackupAutoFrequencyRecommendedTests: XCTestCase {

    private let suite = "backupFreqTests-\(UUID().uuidString)"
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

    func test_recommended_defaultsToOff() {
        XCTAssertEqual(BackupAutoFrequencyStore.recommendedMinDays(defaults: defaults), Int.max)
    }

    func test_recommended_followsUserChoiceWhenNoArchive() {
        BackupAutoFrequencyStore.set(.weekly, in: defaults)
        XCTAssertEqual(BackupAutoFrequencyStore.recommendedMinDays(defaults: defaults), 7)
        BackupAutoFrequencyStore.set(.daily, in: defaults)
        XCTAssertEqual(BackupAutoFrequencyStore.recommendedMinDays(defaults: defaults), 1)
    }

    func test_recommended_overridesToWeeklyWhenArchivePresent() {
        BackupAutoFrequencyStore.set(.off, in: defaults)
        TemplateArchiveStore.setArchived(true, for: UUID(), in: defaults)
        defer { TemplateArchiveStore.clear(in: defaults) }
        XCTAssertEqual(BackupAutoFrequencyStore.recommendedMinDays(defaults: defaults), 7)
    }
}
