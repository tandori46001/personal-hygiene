import Foundation

/// Round-13 slice 32: per-contact gift idea (free-form text). Stored as a
/// JSON dict `[contactID: ideaText]` in UserDefaults.
public enum BirthdayIdeaStore {

    public static let key = "birthdays.giftIdeas"

    public static func dictionary(defaults: UserDefaults = .standard) -> [String: String] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    public static func idea(for contactID: String, defaults: UserDefaults = .standard) -> String? {
        let dict = dictionary(defaults: defaults)
        let value = dict[contactID]?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    public static func set(
        _ idea: String?,
        for contactID: String,
        in defaults: UserDefaults = .standard
    ) {
        var current = dictionary(defaults: defaults)
        let trimmed = idea?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            current[contactID] = trimmed
        } else {
            current.removeValue(forKey: contactID)
        }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
