import Foundation
import UserNotifications

/// JSON-serializable snapshot of the in-app diagnostics surfaces. Built at
/// share time so the user can attach the file to a bug report; intentionally
/// excludes notification *content* (titles, bodies) so a leaked snapshot
/// doesn't expose private medication identifiers — only structural info
/// (counts, identifiers, timestamps) that's useful for triage.
public struct DiagnosticsSnapshot: Codable, Sendable {

    public struct RefreshTraceEntryDTO: Codable, Sendable {
        public let timestamp: Date
        public let scheduledCount: Int
        public let kind: String
    }

    public struct PendingNotificationSummary: Codable, Sendable {
        public let identifier: String
        public let triggerDate: Date?
    }

    public let buildVersion: String
    public let bundleVersion: String
    public let commitSHA: String
    public let processLaunchedAt: Date
    public let processUptimeSeconds: TimeInterval
    public let pendingCount: Int
    public let deliveredCount: Int
    public let widgetReloadCount: Int
    public let medicationObserverAvailable: Bool
    public let medicationObserverIdentifiers: [String]
    public let tripDocumentCount: Int
    public let tripDocumentByteFootprint: Int?
    public let refreshTrace: [RefreshTraceEntryDTO]
    public let pendingSummary: [PendingNotificationSummary]
    public let snapshotAt: Date

    @MainActor
    public static func capture(
        widgetReloadCount: Int,
        observerAvailable: Bool,
        observerIdentifiers: [String],
        tripDocumentCount: Int,
        tripDocumentByteFootprint: Int?
    ) async -> Self {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        let trace = RefreshTraceLog.shared.entries.map {
            RefreshTraceEntryDTO(
                timestamp: $0.timestamp,
                scheduledCount: $0.scheduledCount,
                kind: $0.kind.rawValue
            )
        }
        let pendingSummary = pending.map { req -> PendingNotificationSummary in
            let triggerDate = (req.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                ?? (req.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
            return PendingNotificationSummary(
                identifier: req.identifier,
                triggerDate: triggerDate
            )
        }
        return Self(
            buildVersion: BuildInfo.marketingVersion,
            bundleVersion: BuildInfo.bundleVersion,
            commitSHA: BuildInfo.commitSHA,
            processLaunchedAt: ProcessLaunchTimer.launchedAt,
            processUptimeSeconds: ProcessLaunchTimer.uptimeSeconds(),
            pendingCount: pending.count,
            deliveredCount: delivered.count,
            widgetReloadCount: widgetReloadCount,
            medicationObserverAvailable: observerAvailable,
            medicationObserverIdentifiers: observerIdentifiers,
            tripDocumentCount: tripDocumentCount,
            tripDocumentByteFootprint: tripDocumentByteFootprint,
            refreshTrace: trace,
            pendingSummary: pendingSummary,
            snapshotAt: Date()
        )
    }

    public func encodedJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public func writeToTemporaryFile(filename: String? = nil) throws -> URL {
        let name = filename
            ?? "personal-hygiene-diagnostics-\(Int(Date().timeIntervalSince1970)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try encodedJSON().write(to: url, options: .atomic)
        return url
    }
}
