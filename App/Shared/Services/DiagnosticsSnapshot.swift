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

    /// Round-12 slice 15: app build settings captured for cross-device debug.
    public let localeIdentifier: String?
    public let calendarIdentifier: String?
    public let timeZoneIdentifier: String?
    /// Round-12 slice 1: per-category pending breakdown.
    public let pendingByCategory: PendingByCategoryDTO?

    public struct PendingByCategoryDTO: Codable, Sendable {
        public let routine: Int
        public let medicationFollowUp: Int
        public let hydration: Int
        public let milestones: Int
        public let housekeeping: Int
        public let other: Int

        public init(_ counts: PendingNotificationsByCategory) {
            self.routine = counts.routine
            self.medicationFollowUp = counts.medicationFollowUp
            self.hydration = counts.hydration
            self.milestones = counts.milestones
            self.housekeeping = counts.housekeeping
            self.other = counts.other
        }
    }

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
        let counts = PendingNotificationsByCategory.fromPending(pending)
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
            snapshotAt: Date(),
            localeIdentifier: Locale.current.identifier,
            calendarIdentifier: Calendar.current.identifier.debugDescription,
            timeZoneIdentifier: TimeZone.current.identifier,
            pendingByCategory: PendingByCategoryDTO(counts)
        )
    }

    /// Round-12 slice 16: pure delta between two snapshots — used by the
    /// "Compare with last snapshot" button to surface scalar changes.
    public struct Diff: Equatable, Sendable {
        public let pendingDelta: Int
        public let deliveredDelta: Int
        public let widgetReloadDelta: Int
        public let tripDocCountDelta: Int
        public let observerIdentifierAdditions: [String]
        public let observerIdentifierRemovals: [String]
        public let buildChanged: Bool
    }

    public static func diff(from older: Self, to newer: Self) -> Diff {
        let oldIDs = Set(older.medicationObserverIdentifiers)
        let newIDs = Set(newer.medicationObserverIdentifiers)
        return Diff(
            pendingDelta: newer.pendingCount - older.pendingCount,
            deliveredDelta: newer.deliveredCount - older.deliveredCount,
            widgetReloadDelta: newer.widgetReloadCount - older.widgetReloadCount,
            tripDocCountDelta: newer.tripDocumentCount - older.tripDocumentCount,
            observerIdentifierAdditions: Array(newIDs.subtracting(oldIDs)).sorted(),
            observerIdentifierRemovals: Array(oldIDs.subtracting(newIDs)).sorted(),
            buildChanged: older.commitSHA != newer.commitSHA
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
