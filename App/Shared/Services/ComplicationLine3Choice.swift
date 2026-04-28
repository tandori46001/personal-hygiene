import Foundation

/// Round-25 slice T6.42: stores the user's preference for the line-3 slot
/// of the rectangular `NextBlockComplication`. Defaults to dayCompletion.
public enum ComplicationLine3Choice {

    public static let key = "complication.line3.choice.v1"

    public enum Choice: String, CaseIterable, Sendable {
        case dayCompletion
        case mood
        case medicationStreak
    }

    public static func current(in defaults: UserDefaults = .standard) -> Choice {
        let raw = defaults.string(forKey: key) ?? Choice.dayCompletion.rawValue
        return Choice(rawValue: raw) ?? .dayCompletion
    }

    public static func set(
        _ choice: Choice,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(choice.rawValue, forKey: key)
    }
}
