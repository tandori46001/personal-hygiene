@testable import PersonalHygiene
import XCTest

final class MoodTrendAggregatorTests: XCTestCase {

    private func calendar() -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ daysFrom: Int, hour: Int = 12) -> Date {
        let cal = calendar()
        let base = DateComponents(
            calendar: cal, timeZone: cal.timeZone,
            year: 2026, month: 4, day: 28, hour: hour
        ).date!
        return cal.date(byAdding: .day, value: daysFrom, to: base)!
    }

    func test_bins_yieldsOneBucketPerDayWithGaps() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(0)),
            MoodLogStore.Entry(mood: .bad, recordedAt: date(-2)),
        ]
        let bins = MoodTrendAggregator.bins(from: entries, days: 5, endingAt: date(0), calendar: calendar())
        XCTAssertEqual(bins.count, 5)
        XCTAssertNil(bins[0].score, "no entry day appears as nil")
        XCTAssertEqual(bins.last?.score, 5.0)
        XCTAssertEqual(bins.last?.count, 1)
    }

    func test_bins_averagesMultipleEntriesPerDay() throws {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(0, hour: 10)),
            MoodLogStore.Entry(mood: .bad, recordedAt: date(0, hour: 18)),
        ]
        let bins = MoodTrendAggregator.bins(from: entries, days: 1, endingAt: date(0), calendar: calendar())
        XCTAssertEqual(bins.count, 1)
        let score = try XCTUnwrap(bins[0].score)
        XCTAssertEqual(score, (5.0 + 2.0) / 2.0, accuracy: 0.001)
        XCTAssertEqual(bins[0].count, 2)
    }

    func test_bins_excludesEntriesOutsideWindow() {
        let entries = [
            MoodLogStore.Entry(mood: .great, recordedAt: date(-5)),
            MoodLogStore.Entry(mood: .good, recordedAt: date(0)),
        ]
        let bins = MoodTrendAggregator.bins(from: entries, days: 3, endingAt: date(0), calendar: calendar())
        let totalEntries = bins.reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalEntries, 1, "older entry outside window dropped")
    }

    func test_score_isMonotonicAcrossMoodOrdering() {
        let scores = MoodLogStore.Mood.allCases.map(MoodTrendAggregator.score(for:))
        XCTAssertEqual(scores, [5, 4, 3, 2, 1], "great > good > okay > bad > awful")
    }
}
