import Foundation

/// Round-12 slice 28: per-category notification mute toggles. The user can
/// silence Hydration, Housekeeping, Birthdays, or Trip-milestone reminders
/// without having to delete the underlying schedule. Coordinator + factories
/// consult these flags before producing notification requests.
public enum NotificationCategoryMuteStore {

    public enum Category: String, CaseIterable, Sendable {
        case hydration
        case housekeeping
        case birthdays
        case milestones
        case medication

        public var defaultsKey: String { "notifications.mute.\(rawValue)" }
    }

    public static func isMuted(
        _ category: Category,
        defaults: UserDefaults = .standard
    ) -> Bool {
        defaults.bool(forKey: category.defaultsKey)
    }

    public static func setMuted(
        _ value: Bool,
        for category: Category,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(value, forKey: category.defaultsKey)
    }

    public static func clearAll(in defaults: UserDefaults = .standard) {
        for category in Category.allCases {
            defaults.removeObject(forKey: category.defaultsKey)
        }
    }
}
