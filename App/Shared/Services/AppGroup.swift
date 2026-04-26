import Foundation

/// Single source of truth for the App Group identifier shared between the
/// iOS host app and its widget extensions. Stored as a constant so that when
/// the entitlement is added in Apple Developer Portal, only this file (and
/// the entitlement plists) need to change.
///
/// The widgets read user-configured state (focus schedule, snooze badges,
/// `SnoozeDurationStore`) via `UserDefaults(suiteName: AppGroup.suiteName)`.
/// Until the entitlement ships, `UserDefaults(suiteName:)` returns nil for a
/// suite that doesn't exist on disk and callers fall back to `.standard`.
public enum AppGroup {
    public static let suiteName = "group.com.tandori46001.personalhygiene"
}
