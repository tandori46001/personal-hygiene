import Foundation
import UserNotifications

public enum NotificationAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    init(_ raw: UNAuthorizationStatus) {
        switch raw {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .provisional: self = .provisional
        case .ephemeral: self = .ephemeral
        @unknown default: self = .notDetermined
        }
    }
}

@MainActor
public protocol NotificationService {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization(criticalAlerts: Bool) async throws -> Bool

    /// Cancel pending notifications whose identifier starts with `prefix`, then
    /// schedule the given notifications. Notifications with a different prefix
    /// are left untouched, so block + milestone schedulers can coexist.
    func scheduleAll(_ notifications: [ScheduledNotification], cancellingPrefix prefix: String) async throws

    /// Cancel all pending notifications whose identifier starts with `prefix`.
    func cancelAll(withPrefix prefix: String) async
}

extension NotificationService {

    /// Convenience overload that cancels + reschedules using the routine block prefix.
    public func scheduleAll(_ notifications: [ScheduledNotification]) async throws {
        try await scheduleAll(notifications, cancellingPrefix: NotificationFactory.identifierPrefix)
    }

    /// Convenience overload that cancels every routine block notification.
    public func cancelAll() async {
        await cancelAll(withPrefix: NotificationFactory.identifierPrefix)
    }
}

@MainActor
public final class UserNotificationsService: NotificationService {

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return NotificationAuthorizationStatus(settings.authorizationStatus)
    }

    public func requestAuthorization(criticalAlerts: Bool) async throws -> Bool {
        var options: UNAuthorizationOptions = [.alert, .sound, .badge]
        if criticalAlerts {
            options.insert(.criticalAlert)
        }
        return try await center.requestAuthorization(options: options)
    }

    public func cancelAll(withPrefix prefix: String) async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func scheduleAll(
        _ notifications: [ScheduledNotification],
        cancellingPrefix prefix: String
    ) async throws {
        await cancelAll(withPrefix: prefix)
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            if let body = notification.body, !body.isEmpty {
                content.body = body
            }
            content.sound =
                notification.isCritical
                ? .defaultCritical
                : .default
            if notification.isCritical {
                content.interruptionLevel = .critical
            }
            content.threadIdentifier = notification.threadIdentifier
            if let categoryID = notification.categoryIdentifier {
                content.categoryIdentifier = categoryID
            }

            let triggerComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: notification.triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: notification.identifier,
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }
    }
}

/// Registers `UNNotificationCategory`s on launch so the user sees the snooze
/// + mark-done actions when long-pressing a routine notification. Critical
/// medication alerts intentionally only get "Mark done" — we never want a
/// snooze button on a medication reminder.
public enum NotificationCategoryRegistrar {

    @MainActor
    public static func register(center: UNUserNotificationCenter = .current()) {
        let snooze = UNNotificationAction(
            identifier: NotificationActionID.snooze5min,
            title: NSLocalizedString(
                "notification.action.snooze5min",
                comment: "Push action that re-fires the alert in 5 minutes"
            ),
            options: []
        )
        let markDone = UNNotificationAction(
            identifier: NotificationActionID.markDone,
            title: NSLocalizedString(
                "notification.action.markDone",
                comment: "Push action that marks the block as done"
            ),
            options: []
        )

        let routine = UNNotificationCategory(
            identifier: NotificationCategoryID.routineBlock,
            actions: [markDone, snooze],
            intentIdentifiers: [],
            options: []
        )
        let medication = UNNotificationCategory(
            identifier: NotificationCategoryID.medication,
            actions: [markDone],
            intentIdentifiers: [],
            options: []
        )
        let milestone = UNNotificationCategory(
            identifier: NotificationCategoryID.tripMilestone,
            actions: [snooze],
            intentIdentifiers: [],
            options: []
        )
        let hydration = UNNotificationCategory(
            identifier: NotificationCategoryID.hydration,
            actions: [snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([routine, medication, milestone, hydration])
    }
}

/// `UNUserNotificationCenterDelegate` wrapper that handles the snooze action
/// by re-firing the notification 5 minutes later with the same content.
///
/// The class itself is not main-actor-isolated; the system invokes delegate
/// callbacks on a background queue. Snooze rescheduling hops to a Task and
/// uses the (concurrency-safe) async API on `UNUserNotificationCenter`.
public final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {

    public static let snoozeDelay: TimeInterval = 5 * 60

    override public init() {
        super.init()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        guard response.actionIdentifier == NotificationActionID.snooze5min else {
            completionHandler()
            return
        }
        let identifier = response.notification.request.identifier
        let original = response.notification.request
        let content = (original.content.mutableCopy() as? UNMutableNotificationContent)
            ?? UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Self.snoozeDelay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(identifier).snooze.\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        // Use the completion-handler API instead of `await center.add(request)`
        // so we don't have to capture `completionHandler` across an actor hop.
        center.add(request) { _ in completionHandler() }
    }
}
