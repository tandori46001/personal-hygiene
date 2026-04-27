import UserNotifications
import XCTest

@testable import PersonalHygiene

final class NotificationActionHandlerTests: XCTestCase {

    func test_snoozeRequest_usesProvidedInterval() {
        let original = UNNotificationRequest(
            identifier: "block.123",
            content: UNMutableNotificationContent(),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let request = NotificationActionHandler.makeSnoozeRequest(
            from: original,
            interval: 600,
            now: now
        )

        let trigger = request.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertEqual(trigger?.timeInterval, 600)
    }

    func test_snoozeRequest_identifierIncludesOriginalAndTimestamp() {
        let original = UNNotificationRequest(
            identifier: "block.abc",
            content: UNMutableNotificationContent(),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let request = NotificationActionHandler.makeSnoozeRequest(
            from: original,
            interval: 300,
            now: now
        )

        XCTAssertTrue(request.identifier.hasPrefix("block.abc.snooze."))
        XCTAssertTrue(request.identifier.contains("\(Int(now.timeIntervalSince1970))"))
    }

    func test_snoozeRequest_preservesContent() {
        let content = UNMutableNotificationContent()
        content.title = "Aseo"
        content.body = "Hora de la rutina"
        content.threadIdentifier = NotificationThreadID.routine
        let original = UNNotificationRequest(
            identifier: "block.x",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        let request = NotificationActionHandler.makeSnoozeRequest(
            from: original,
            interval: 300,
            now: Date()
        )

        XCTAssertEqual(request.content.title, "Aseo")
        XCTAssertEqual(request.content.body, "Hora de la rutina")
        XCTAssertEqual(request.content.threadIdentifier, NotificationThreadID.routine)
    }

    // MARK: - SnoozeDurationStore

    private func cleanDefaults(_ key: String) -> UserDefaults {
        let suite = UserDefaults(suiteName: "snooze-test-\(UUID().uuidString)")!
        suite.removeObject(forKey: key)
        return suite
    }

    func test_snoozeDuration_defaultsToFiveMinutesWhenUnset() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 5)
        XCTAssertEqual(SnoozeDurationStore.seconds(defaults: defaults), 300)
    }

    func test_snoozeDuration_acceptsAllowedValues() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        SnoozeDurationStore.set(10, in: defaults)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 10)
        SnoozeDurationStore.set(15, in: defaults)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 15)
    }

    func test_snoozeDuration_rejectsInvalidValuesAndFallsBackToDefault() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        // Bypass the setter to plant an invalid value directly.
        defaults.set(7, forKey: SnoozeDurationStore.key)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 5)
    }

    func test_snoozeDuration_setterIgnoresOutOfRangeValues() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        SnoozeDurationStore.set(10, in: defaults)
        SnoozeDurationStore.set(99, in: defaults)  // ignored
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 10)
    }

    // MARK: - Boundary value coverage (slice 9)

    func test_snoozeDuration_setterAcceptsFiveExplicitly() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        SnoozeDurationStore.set(10, in: defaults)
        SnoozeDurationStore.set(5, in: defaults)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 5)
        XCTAssertEqual(SnoozeDurationStore.seconds(defaults: defaults), 300)
    }

    func test_snoozeDuration_zeroAndNegativeAreRejected() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        SnoozeDurationStore.set(15, in: defaults)
        SnoozeDurationStore.set(0, in: defaults)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 15)
        SnoozeDurationStore.set(-5, in: defaults)
        XCTAssertEqual(SnoozeDurationStore.minutes(defaults: defaults), 15)
    }

    func test_snoozeDuration_secondsMatchesMinutesTimes60ForEachAllowedValue() {
        let defaults = cleanDefaults(SnoozeDurationStore.key)
        for minutes in SnoozeDurationStore.allowedMinutes {
            SnoozeDurationStore.set(minutes, in: defaults)
            XCTAssertEqual(SnoozeDurationStore.seconds(defaults: defaults), TimeInterval(minutes * 60))
        }
    }

    func test_snoozeDuration_allowedMinutesContains_5_10_15() {
        XCTAssertEqual(Set(SnoozeDurationStore.allowedMinutes), [5, 10, 15])
    }

    // MARK: - markDone integration (round 6 slice 9)

    /// Thread-safe collector for `@Sendable` test closures that need to
    /// accumulate values without tripping Swift 6 strict concurrency.
    private final class Collector<Element: Sendable>: @unchecked Sendable {
        private let lock = NSLock()
        private var items: [Element] = []
        func append(_ value: Element) { lock.lock(); defer { lock.unlock() }; items.append(value) }
        func append(contentsOf values: [Element]) {
            lock.lock(); defer { lock.unlock() }
            items.append(contentsOf: values)
        }
        var snapshot: [Element] { lock.lock(); defer { lock.unlock() }; return items }
    }

    func test_markDone_removesPendingForExactIdentifierAndFiresObserver() {
        let identifier = "personal-hygiene.block.\(UUID().uuidString).2026-04-26"
        let removed = Collector<String>()
        let observed = Collector<String>()

        let handler = NotificationActionHandler(
            snoozeIntervalProvider: { 300 },
            nowProvider: { Date() },
            markDoneObserver: { observed.append($0) }
        )

        handler.handleMarkDoneAction(identifier: identifier) { ids in
            removed.append(contentsOf: ids)
        }

        XCTAssertEqual(removed.snapshot, [identifier])
        XCTAssertEqual(observed.snapshot, [identifier])
    }

    func test_markDone_doesNotRemoveOtherIdentifiers() {
        let target = "personal-hygiene.block.\(UUID().uuidString).2026-04-26"
        let other = "personal-hygiene.hydration.2026-04-26.0"
        let removed = Collector<String>()

        let handler = NotificationActionHandler(snoozeIntervalProvider: { 300 })
        handler.handleMarkDoneAction(identifier: target) { ids in
            removed.append(contentsOf: ids)
        }

        XCTAssertTrue(removed.snapshot.contains(target))
        XCTAssertFalse(removed.snapshot.contains(other))
    }

    // MARK: - WidgetCenter reload wiring (round 9 slice 17)

    /// Thread-safe int counter for `@Sendable` test closures.
    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0
        func increment() { lock.lock(); defer { lock.unlock() }; count += 1 }
        var value: Int { lock.lock(); defer { lock.unlock() }; return count }
    }

    func test_markDone_invokesWidgetReloaderExactlyOnce() {
        let identifier = "personal-hygiene.block.\(UUID().uuidString).2026-04-26"
        let widgetReloads = Counter()

        let handler = NotificationActionHandler(
            snoozeIntervalProvider: { 300 },
            widgetReloader: { widgetReloads.increment() }
        )

        handler.handleMarkDoneAction(identifier: identifier) { _ in }

        XCTAssertEqual(widgetReloads.value, 1)
    }

    func test_markDone_widgetReloadFiresAfterMarkDoneObserver() {
        let identifier = "personal-hygiene.block.\(UUID().uuidString).2026-04-26"
        let order = Collector<String>()

        let handler = NotificationActionHandler(
            snoozeIntervalProvider: { 300 },
            markDoneObserver: { _ in order.append("observer") },
            widgetReloader: { order.append("reload") }
        )

        handler.handleMarkDoneAction(identifier: identifier) { _ in
            order.append("removed")
        }

        XCTAssertEqual(order.snapshot, ["removed", "observer", "reload"])
    }
}
