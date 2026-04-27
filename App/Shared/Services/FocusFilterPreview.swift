import Foundation

/// Round-16: pure helper that answers "given the current Focus state, which
/// blocks would the deep-focus filter silence right now?". Wraps the
/// existing `DeepFocusFilter.activeWindow` + `focusWindows` machinery so the
/// caller doesn't have to reason about windows + blocks separately.
public enum FocusFilterPreview {

    public struct Result: Equatable {
        public let activeBlock: Block?
        public let silencedBlocks: [Block]
    }

    public static func preview(
        at now: Date = Date(),
        in blocks: [Block],
        scheduledWindows: [ScheduledFocusWindow],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Result {
        let active = DeepFocusFilter.activeWindow(
            at: now,
            in: blocks,
            scheduledWindows: scheduledWindows,
            calendar: calendar
        )
        // Match the active window back to a block (if any) by title — that's
        // the only field we have access to without leaking IDs through the
        // window struct.
        let activeBlock = active.flatMap { window in
            blocks.first { $0.title == window.blockTitle && $0.isDeepFocus }
        }
        guard active != nil else {
            return Result(activeBlock: nil, silencedBlocks: [])
        }
        // While a focus window is active, every non-deepFocus block that
        // would fire inside the window is silenced. We approximate by
        // checking whether the block's start time today is inside the window.
        let dayStart = calendar.startOfDay(for: now)
        let silenced = blocks.compactMap { block -> Block? in
            guard !block.isDeepFocus else { return nil }
            guard let blockTime = calendar.date(
                byAdding: .minute,
                value: block.startMinutesFromMidnight,
                to: dayStart
            ) else { return nil }
            return active.flatMap { $0.contains(blockTime) ? block : nil }
        }
        return Result(activeBlock: activeBlock, silencedBlocks: silenced)
    }
}
