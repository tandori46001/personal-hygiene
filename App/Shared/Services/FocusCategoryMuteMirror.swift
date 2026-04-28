import Foundation

/// Round-21 slice T6.34: snapshot of the iOS-side per-category mute state
/// into the App Group suite so the watch can read it via the same key path.
/// Until the App Group entitlement ships this falls back to `.standard`
/// (no actual cross-process sync, but the surface is in place).
public enum FocusCategoryMuteMirror {

    public static let key = "focus.categoryMute.mirror.v1"

    public static func mirror(
        from defaults: UserDefaults = .standard,
        to sharedDefaults: UserDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    ) {
        let map = NotificationCategoryMuteStore.allMuted(defaults: defaults)
        let payload = map.map { $0.rawValue }
        sharedDefaults.set(payload, forKey: key)
    }

    public static func mirroredCategories(
        in sharedDefaults: UserDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    ) -> Set<NotificationCategoryMuteStore.Category> {
        let raw = sharedDefaults.array(forKey: key) as? [String] ?? []
        return Set(raw.compactMap { NotificationCategoryMuteStore.Category(rawValue: $0) })
    }

    public static func clear(
        in sharedDefaults: UserDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    ) {
        sharedDefaults.removeObject(forKey: key)
    }
}
