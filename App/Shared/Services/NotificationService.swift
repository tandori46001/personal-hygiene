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
    func scheduleAll(_ notifications: [ScheduledNotification]) async throws
    func cancelAll() async
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

    public func cancelAll() async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(NotificationFactory.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public func scheduleAll(_ notifications: [ScheduledNotification]) async throws {
        await cancelAll()
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
