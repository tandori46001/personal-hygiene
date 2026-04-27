import Foundation

/// Round-13 slice 19: rolling timeline of notification authorization status
/// changes. Used to debug "why aren't I getting notifications" — surfaces
/// when permission was revoked or downgraded vs when the user explicitly
/// granted it. Persisted across launches.
public enum NotificationAuthTimelineLog {

    public static let key = "notifications.authTimeline"
    public static let capacity = 20

    public struct Entry: Codable, Equatable, Sendable, Identifiable {
        public let id: UUID
        public let timestamp: Date
        public let statusRawValue: String

        public init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            statusRawValue: String
        ) {
            self.id = id
            self.timestamp = timestamp
            self.statusRawValue = statusRawValue
        }
    }

    public static func entries(defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    /// Record a status sample. No-op when the most recent entry has the same
    /// status — we only care about *changes*, not periodic resampling.
    public static func record(
        statusRawValue: String,
        at date: Date = Date(),
        in defaults: UserDefaults = .standard
    ) {
        var current = entries(defaults: defaults)
        if current.first?.statusRawValue == statusRawValue { return }
        current.insert(Entry(timestamp: date, statusRawValue: statusRawValue), at: 0)
        if current.count > capacity { current = Array(current.prefix(capacity)) }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
