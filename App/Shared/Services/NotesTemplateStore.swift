import Foundation

/// Round-13 slice 8: reusable trip-notes snippets the user can paste into a
/// new trip. Stored as a JSON array of `(title, body)` tuples in UserDefaults
/// so we don't need a new SwiftData @Model for what is essentially a small
/// per-user prefs list.
public enum NotesTemplateStore {

    public static let key = "trip.notesTemplates"

    public struct Entry: Codable, Equatable, Sendable, Identifiable {
        public let id: UUID
        public let title: String
        public let body: String

        public init(id: UUID = UUID(), title: String, body: String) {
            self.id = id
            self.title = title
            self.body = body
        }
    }

    public static func entries(defaults: UserDefaults = .standard) -> [Entry] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    public static func add(
        title: String,
        body: String,
        in defaults: UserDefaults = .standard
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedBody.isEmpty else { return }
        var current = entries(defaults: defaults)
        current.append(Entry(title: trimmedTitle, body: trimmedBody))
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func remove(id: UUID, in defaults: UserDefaults = .standard) {
        var current = entries(defaults: defaults)
        current.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
