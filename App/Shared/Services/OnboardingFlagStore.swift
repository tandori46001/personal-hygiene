import Foundation

/// Single point of truth for the "has the user completed onboarding?" flag.
/// Settings exposes `reset()` so the user can replay the welcome flow without
/// reinstalling the app; UI tests also drive this via `-uiTestReset`.
public enum OnboardingFlagStore {

    public static let key = "hasCompletedOnboarding"

    public static func reset(defaults: UserDefaults = .standard) {
        defaults.set(false, forKey: key)
    }
}
