@preconcurrency import XCTest

@testable import PersonalHygiene

final class OnboardingFlagStoreTests: XCTestCase {

    private func cleanDefaults() -> UserDefaults {
        let suite = UserDefaults(suiteName: "onboarding-test-\(UUID().uuidString)")!
        suite.removeObject(forKey: OnboardingFlagStore.key)
        return suite
    }

    func test_reset_setsFlagToFalse() {
        let defaults = cleanDefaults()
        defaults.set(true, forKey: OnboardingFlagStore.key)

        OnboardingFlagStore.reset(defaults: defaults)

        XCTAssertEqual(defaults.bool(forKey: OnboardingFlagStore.key), false)
    }

    func test_reset_isIdempotent() {
        let defaults = cleanDefaults()
        OnboardingFlagStore.reset(defaults: defaults)
        OnboardingFlagStore.reset(defaults: defaults)
        XCTAssertEqual(defaults.bool(forKey: OnboardingFlagStore.key), false)
    }

    func test_defaultColdStartIsFalse() {
        // A brand-new UserDefaults suite has no value for the key; bool reads
        // as false by default — equivalent to "onboarding not yet completed",
        // which is what we want for first launch.
        let defaults = cleanDefaults()
        XCTAssertEqual(defaults.bool(forKey: OnboardingFlagStore.key), false)
    }

    func test_keyMatchesAppStorageContract() {
        // The flag key is the contract between OnboardingFlagStore.reset() and
        // ContentView's @AppStorage("hasCompletedOnboarding"). If anyone renames
        // the key, the reset stops actually resetting onboarding.
        XCTAssertEqual(OnboardingFlagStore.key, "hasCompletedOnboarding")
    }
}
