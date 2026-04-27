import Foundation

/// Round-12 slice 18: rolling history of commit SHAs the auto-popup
/// "What's new" sheet has shown. Surfaced in DiagnosticsView so a regression
/// can be traced back to the last few builds the device installed.
public enum WhatsNewHistoryStore {

    public static let key = "whatsNew.history"
    public static let capacity = 5

    public struct Entry: Codable, Equatable, Sendable, Identifiable {
        public let id: UUID
        public let commitSHA: String
        public let seenAt: Date

        public init(id: UUID = UUID(), commitSHA: String, seenAt: Date = Date()) {
            self.id = id
            self.commitSHA = commitSHA
            self.seenAt = seenAt
        }
    }

    public static func history(defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    public static func record(
        commitSHA: String,
        at date: Date = Date(),
        in defaults: UserDefaults = .standard
    ) {
        var current = history(defaults: defaults)
        if current.first?.commitSHA == commitSHA { return }
        current.insert(Entry(commitSHA: commitSHA, seenAt: date), at: 0)
        if current.count > capacity { current = Array(current.prefix(capacity)) }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
