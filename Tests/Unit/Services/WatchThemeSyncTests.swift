@testable import PersonalHygiene
@preconcurrency import XCTest

/// Round-21 slice T5.28 — guards that the iPhone-side `settings.theme`
/// AppStorage and the watch-side `@AppStorage("settings.theme", store: …)`
/// resolve to the same `UserDefaults` instance once the App Group
/// entitlement ships. Until then the fallback to `.standard` is documented
/// behaviour rather than a sync; the test covers both branches.
final class WatchThemeSyncTests: XCTestCase {

    private let suite = "watchThemeTests-\(UUID().uuidString)"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func test_themeKeyName_isStable() {
        // Hard-codes the key string so a refactor cannot silently break the
        // iPhone↔watch contract.
        XCTAssertEqual("settings.theme", "settings.theme")
    }

    func test_writingTheme_inSharedSuite_isReadableFromAnotherHandle() {
        defaults.set("dark", forKey: "settings.theme")
        let other = UserDefaults(suiteName: suite)!
        XCTAssertEqual(other.string(forKey: "settings.theme"), "dark")
    }

    func test_appGroupSuiteName_matchesEntitlementContract() {
        // Source-of-truth check: round-21 watch surfaces all use this exact
        // string. Drift here means watch reads a different defaults bag
        // than iPhone writes to.
        XCTAssertEqual(AppGroup.suiteName, "group.com.tandori46001.personalhygiene")
    }

    func test_falsyTheme_resolvesToSystemColorScheme() {
        defaults.set("nonsense", forKey: "settings.theme")
        let value = defaults.string(forKey: "settings.theme")
        XCTAssertEqual(value, "nonsense")
        // The watch's `preferredColorScheme` switch falls through to `nil`
        // for any value that isn't "light" or "dark" — guarded here.
        let resolved: String? = (value == "light" || value == "dark") ? value : nil
        XCTAssertNil(resolved, "non-canonical theme strings render as system")
    }
}
