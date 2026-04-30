@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-22 slice T1.3 — guards `MoodTrendAggregator.symbol(for:)` rounding
/// thresholds. Round 21 added the helper for the Today week strip without
/// dedicated coverage; pinning the rounding boundaries here so a refactor
/// can't silently shift which emoji a borderline daily-average resolves to.
final class MoodTrendAggregatorSymbolTests: XCTestCase {

    func test_symbol_clampedToHigherEmojiAtMidpoints() {
        // Swift's Double.rounded() defaults to .toNearestOrEven; the helper
        // therefore rounds 4.5 → 4 and 4.6 → 5.
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 5.0), MoodLogStore.Mood.great.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 4.6), MoodLogStore.Mood.great.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 4.0), MoodLogStore.Mood.good.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 3.0), MoodLogStore.Mood.okay.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 2.0), MoodLogStore.Mood.bad.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 1.0), MoodLogStore.Mood.awful.emoji)
    }

    func test_symbol_belowOneCollapsesToAwful() {
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 0.4), MoodLogStore.Mood.awful.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: -2), MoodLogStore.Mood.awful.emoji)
    }

    func test_symbol_aboveFiveStaysAtGreat() {
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 6.0), MoodLogStore.Mood.great.emoji)
        XCTAssertEqual(MoodTrendAggregator.symbol(for: 100), MoodLogStore.Mood.great.emoji)
    }
}
