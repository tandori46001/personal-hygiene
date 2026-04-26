import Foundation

/// Pure helpers around the `Block.isDeepFocus` flag. Deep-focus blocks
/// represent windows in the day where non-critical notifications should be
/// suppressed and the UI can show a "Focus on" indicator.
public enum DeepFocusFilter {

    public struct FocusWindow: Equatable, Sendable {
        public let blockTitle: String
        public let start: Date
        public let end: Date

        public init(blockTitle: String, start: Date, end: Date) {
            self.blockTitle = blockTitle
            self.start = start
            self.end = end
        }

        public func contains(_ date: Date) -> Bool {
            date >= start && date < end
        }
    }

    /// All focus windows for `blocks` on the calendar day of `date`.
    public static func focusWindows(
        for blocks: [Block],
        on date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [FocusWindow] {
        let dayStart = calendar.startOfDay(for: date)
        return
            blocks
            .filter(\.isDeepFocus)
            .compactMap { block -> FocusWindow? in
                guard
                    let start = calendar.date(byAdding: .minute, value: block.startMinutesFromMidnight, to: dayStart),
                    let end = calendar.date(byAdding: .minute, value: block.endMinutesFromMidnight, to: dayStart)
                else { return nil }
                return FocusWindow(blockTitle: block.title, start: start, end: end)
            }
    }

    /// `true` when `now` falls inside any focus window built from `blocks`.
    public static func isFocusActive(
        at now: Date,
        in blocks: [Block],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        focusWindows(for: blocks, on: now, calendar: calendar).contains { $0.contains(now) }
    }

    /// Returns the currently active focus window covering `now`, if any.
    public static func activeWindow(
        at now: Date,
        in blocks: [Block],
        calendar: Calendar = .autoupdatingCurrent
    ) -> FocusWindow? {
        focusWindows(for: blocks, on: now, calendar: calendar).first { $0.contains(now) }
    }

    /// Filter `notifications` removing entries whose trigger lands inside any
    /// focus window — except medication-critical alerts, which always fire.
    public static func suppressing(
        _ notifications: [ScheduledNotification],
        focusWindows: [FocusWindow]
    ) -> [ScheduledNotification] {
        guard !focusWindows.isEmpty else { return notifications }
        return notifications.filter { notification in
            if notification.isCritical { return true }
            return !focusWindows.contains(where: { $0.contains(notification.triggerDate) })
        }
    }
}
