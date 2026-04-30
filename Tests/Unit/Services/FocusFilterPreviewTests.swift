@testable import PersonalHygiene
@preconcurrency import XCTest

final class FocusFilterPreviewTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    private func makeBlock(
        title: String,
        startMinutes: Int,
        durationMinutes: Int,
        deepFocus: Bool
    ) -> Block {
        Block(
            title: title,
            category: .work,
            startMinutesFromMidnight: startMinutes,
            durationMinutes: durationMinutes,
            isDeepFocus: deepFocus
        )
    }

    func test_preview_noActiveWindow_returnsEmpty() {
        let blocks = [makeBlock(title: "Work", startMinutes: 9 * 60, durationMinutes: 60, deepFocus: true)]
        // Now is 8am — before the focus window starts.
        let day = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let now = cal.date(byAdding: .hour, value: 8, to: day)!
        let result = FocusFilterPreview.preview(at: now, in: blocks, scheduledWindows: [])
        XCTAssertNil(result.activeBlock)
        XCTAssertTrue(result.silencedBlocks.isEmpty)
    }

    func test_preview_activeWindow_silencesBlocksInside() {
        let day = cal.date(from: DateComponents(year: 2026, month: 4, day: 27))!
        let now = cal.date(byAdding: .hour, value: 9, to: day)!
        let focusBlock = makeBlock(title: "Deep", startMinutes: 9 * 60, durationMinutes: 60, deepFocus: true)
        let coveredBlock = makeBlock(
            title: "Stand-up",
            startMinutes: 9 * 60 + 30,
            durationMinutes: 15,
            deepFocus: false
        )
        let outsideBlock = makeBlock(
            title: "Lunch",
            startMinutes: 13 * 60,
            durationMinutes: 30,
            deepFocus: false
        )
        let result = FocusFilterPreview.preview(
            at: now,
            in: [focusBlock, coveredBlock, outsideBlock],
            scheduledWindows: [],
            calendar: cal
        )
        XCTAssertEqual(result.activeBlock?.title, "Deep")
        XCTAssertEqual(result.silencedBlocks.map(\.title), ["Stand-up"])
    }
}
