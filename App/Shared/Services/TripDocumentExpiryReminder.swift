import Foundation

/// Round-25 slice T5.36: pure helper that returns documents whose
/// expiration falls within an alerting window. Caller passes the doc list
/// + the configured lead time; the helper does no I/O.
public enum TripDocumentExpiryReminder {

    public struct Document: Equatable, Sendable, Identifiable {
        public let id: UUID
        public let title: String
        public let expiresAt: Date

        public init(id: UUID = UUID(), title: String, expiresAt: Date) {
            self.id = id
            self.title = title
            self.expiresAt = expiresAt
        }
    }

    public static func documentsExpiringWithin(
        leadDays: Int,
        documents: [Document],
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Document] {
        let today = calendar.startOfDay(for: now)
        guard let cutoff = calendar.date(byAdding: .day, value: leadDays, to: today) else {
            return []
        }
        return documents
            .filter { $0.expiresAt >= today && $0.expiresAt <= cutoff }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    public static func daysUntilExpiry(
        for document: Document,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int? {
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: document.expiresAt)
        return calendar.dateComponents([.day], from: today, to: target).day
    }
}
