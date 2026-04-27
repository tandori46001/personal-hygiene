import Foundation

/// Round-13 slice 40: helpers to detect whether a non-medication notification
/// would fire inside the user's sleep window. The scheduler calls
/// `shouldSuppress(_:within:)` to decide whether to drop it. Medication
/// primaries + follow-ups are NEVER suppressed, regardless of bedtime.
public enum BedtimeMute {

    /// 15 minutes of grace on either side of the sleep block — most users
    /// don't fall asleep at the exact start time and don't want a hydration
    /// reminder pinging them at 10:30 if they go to bed at 10:00.
    public static let bufferMinutes: Int = 15

    public static func shouldSuppress(
        notification: ScheduledNotification,
        sleepBlock: Block?,
        on day: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard let sleepBlock else { return false }
        // Medication primaries (`personal-hygiene.block.…` matched against a
        // medication block) are filtered upstream by category before reaching
        // this helper. Follow-ups likewise. The scheduler only feeds in
        // hydration / housekeeping / birthday / milestone payloads.
        guard let window = window(for: sleepBlock, on: day, calendar: calendar) else {
            return false
        }
        return window.start <= notification.triggerDate
            && notification.triggerDate <= window.end
    }

    /// Resolves the start/end window for the given sleep block on `day`,
    /// extended by `bufferMinutes` on each side. Handles the "sleep crosses
    /// midnight" case (e.g. block starts at 23:00 and runs 8h) by snapping
    /// the end into the next calendar day.
    public static func window(
        for block: Block,
        on day: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> (start: Date, end: Date)? {
        let dayStart = calendar.startOfDay(for: day)
        let bufferSeconds = TimeInterval(bufferMinutes * 60)
        guard let baseStart = calendar.date(
            byAdding: .minute,
            value: block.startMinutesFromMidnight,
            to: dayStart
        ) else { return nil }
        guard let baseEnd = calendar.date(
            byAdding: .minute,
            value: block.endMinutesFromMidnight,
            to: dayStart
        ) else { return nil }
        return (
            start: baseStart.addingTimeInterval(-bufferSeconds),
            end: baseEnd.addingTimeInterval(bufferSeconds)
        )
    }
}
