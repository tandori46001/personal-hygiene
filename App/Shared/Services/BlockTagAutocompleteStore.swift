import Foundation

/// Round-25 slice T7.51: persists a recent-tag history that the block
/// editor can suggest when the user starts typing a #tag. Stored as a
/// trailing-50 ring buffer in `UserDefaults`.
public enum BlockTagAutocompleteStore {

    public static let key = "blockEditor.tagHistory.v1"
    public static let capacity = 50

    public static func record(
        _ tag: String,
        in defaults: UserDefaults = .standard
    ) {
        let normalized = tag.trimmingCharacters(in: .whitespaces).lowercased()
        guard !normalized.isEmpty else { return }
        var current = (defaults.array(forKey: key) as? [String]) ?? []
        current.removeAll { $0 == normalized }
        current.append(normalized)
        if current.count > capacity {
            current.removeFirst(current.count - capacity)
        }
        defaults.set(current, forKey: key)
    }

    public static func suggestions(
        prefix: String = "",
        limit: Int = 5,
        in defaults: UserDefaults = .standard
    ) -> [String] {
        let stored = (defaults.array(forKey: key) as? [String]) ?? []
        let normalized = prefix.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered = normalized.isEmpty
            ? stored
            : stored.filter { $0.hasPrefix(normalized) }
        return Array(filtered.reversed().prefix(limit))
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
