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
        /// Round-13 slice 40: bedtime auto-mute toggle. When enabled,
        /// non-medication notifications inside the user's sleep window are
        /// dropped at refresh time.
        case bedtime

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
        // Round-22 slice T2.11: every mute change auto-mirrors the full
        // set into the App Group suite so the watch's
        // `FocusCategoryMuteMirror.mirroredCategories(...)` reflects the
        // change without an extra UI surface.
        FocusCategoryMuteMirror.mirror(from: defaults)
    }

    public static func clearAll(in defaults: UserDefaults = .standard) {
        for category in Category.allCases {
            defaults.removeObject(forKey: category.defaultsKey)
        }
    }

    /// Round-21 slice T6.34: snapshot of every currently-muted category.
    /// Used by `FocusCategoryMuteMirror` to push the iOS-side state into the
    /// App Group suite so the watch can read it.
    public static func allMuted(
        defaults: UserDefaults = .standard
    ) -> Set<Category> {
        var result: Set<Category> = []
        for category in Category.allCases where isMuted(category, defaults: defaults) {
            result.insert(category)
        }
        return result
    }
}
