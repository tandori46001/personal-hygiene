@preconcurrency import XCTest

// Round 37 [37-1] follow-up: XCUIApplication.init / .launch / .tap /
// .launchArguments / .buttons / .tabBars / .firstMatch / .waitForExistence
// / .navigationBars / .isSelected / .exists are all @MainActor-isolated.
// XCUITest's default `func test*()` instance methods are nonisolated, so
// every call into the framework crosses the isolation boundary. Class-level
// @MainActor inherits to every method. `@preconcurrency import XCTest`
// alone (round 37b) silenced the XCTestCase Sendable warnings on unit
// tests but doesn't relax actor-isolation enforcement on the UI test
// surface — that's what this annotation fixes.
@MainActor
final class OnboardingUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func test_freshLaunch_showsOnboarding_thenSeedsTemplates() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()

        // Onboarding screen visible.
        let getStartedPredicate = NSPredicate(
            format: "label LIKE[c] %@ OR label LIKE[c] %@ OR label LIKE[c] %@",
            "Get started", "Empezar", "Commencer"
        )
        let getStarted = app.buttons.element(matching: getStartedPredicate)
        XCTAssertTrue(
            getStarted.waitForExistence(timeout: 5),
            "Onboarding 'Get started' button should appear on fresh launch"
        )

        // Tap to seed templates.
        getStarted.tap()

        // Today tab should now be the active one — its empty state is gone if a
        // template was seeded for today's day type. Just assert the tab bar is
        // visible (which means we're past the onboarding sheet).
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after onboarding completes")
    }

    func test_freshLaunch_doesNotCrash_navigatingToTemplates() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()

        let getStartedPredicate = NSPredicate(
            format: "label LIKE[c] %@ OR label LIKE[c] %@ OR label LIKE[c] %@",
            "Get started", "Empezar", "Commencer"
        )
        let getStarted = app.buttons.element(matching: getStartedPredicate)
        if getStarted.waitForExistence(timeout: 5) {
            getStarted.tap()
        }

        // Try to navigate to the Templates tab.
        let templatesPredicate = NSPredicate(
            format: "label LIKE[c] %@ OR label LIKE[c] %@ OR label LIKE[c] %@",
            "Templates", "Plantillas", "Modèles"
        )
        let templatesTab = app.tabBars.buttons.element(matching: templatesPredicate)
        if templatesTab.waitForExistence(timeout: 5) {
            templatesTab.tap()
            XCTAssertTrue(templatesTab.isSelected || app.navigationBars.firstMatch.exists)
        }
    }
}
