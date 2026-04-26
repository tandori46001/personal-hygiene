import Foundation

/// Pure helper that turns the active routine template + current time into a
/// localized one-liner suitable for a Siri dialog or VoiceOver label. Lives
/// in `Shared/` so the watch widget and iOS App Intent share the exact same
/// phrasing.
public enum WhatsNextDialogBuilder {

    public static func build(template: RoutineTemplate?, at now: Date, calendar: Calendar) -> String {
        guard let template else {
            return String(localized: "intent.whatsNext.noTemplate")
        }
        guard let resolved = NextBlockResolver.resolve(in: template, at: now, calendar: calendar) else {
            return String(localized: "intent.whatsNext.noMore")
        }
        return build(resolved: resolved)
    }

    /// Builds the same dialog from a pre-computed `NextBlockResolver.Result`.
    /// The watch complication and iOS widgets compute this themselves so they
    /// can avoid round-tripping the full template; this overload lets them
    /// share the dialog phrasing without duplicating the template lookup.
    public static func build(resolved: NextBlockResolver.Result) -> String {
        let timeString = String(
            format: "%02d:%02d",
            resolved.startMinutesFromMidnight / 60,
            resolved.startMinutesFromMidnight % 60
        )
        let format = String(
            localized: resolved.isCurrent
                ? "intent.whatsNext.current.format"
                : "intent.whatsNext.upcoming.format"
        )
        return String(format: format, resolved.block.title, timeString)
    }
}
