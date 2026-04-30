@testable import PersonalHygiene
@preconcurrency import XCTest

final class MoodHistogramTests: XCTestCase {

    func test_bins_alwaysEmitsOneBinPerMood() {
        let bins = MoodHistogram.bins(from: [])
        XCTAssertEqual(bins.count, MoodLogStore.Mood.allCases.count)
        // swiftlint:disable:next empty_count
        XCTAssertTrue(bins.allSatisfy { $0.count == 0 })
    }

    func test_bins_countsEachMoodSeparately() {
        let now = Date()
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: now),
            MoodLogStore.Entry(mood: .great, recordedAt: now),
            MoodLogStore.Entry(mood: .bad, recordedAt: now),
        ]
        let bins = MoodHistogram.bins(from: entries)
        let great = bins.first(where: { $0.mood == .great })
        let bad = bins.first(where: { $0.mood == .bad })
        let okay = bins.first(where: { $0.mood == .okay })
        XCTAssertEqual(great?.count, 2)
        XCTAssertEqual(bad?.count, 1)
        XCTAssertEqual(okay?.count, 0)
    }
}
