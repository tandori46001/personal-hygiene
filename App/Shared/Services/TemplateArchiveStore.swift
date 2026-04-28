import Foundation

/// Round-23 slice T4.20: per-template archive flag stored in UserDefaults.
/// Archive ≠ delete — the template stays in the SwiftData store but the UI
/// can hide it from the primary list. Designed as a passive companion to
/// `RoutineTemplate.isActive`; archive overrides "show".
public enum TemplateArchiveStore {

    public static let key = "templates.archived.v1"

    public static func isArchived(_ id: UUID, in defaults: UserDefaults = .standard) -> Bool {
        let archived = defaults.array(forKey: key) as? [String] ?? []
        return archived.contains(id.uuidString)
    }

    public static func setArchived(
        _ value: Bool,
        for id: UUID,
        in defaults: UserDefaults = .standard
    ) {
        var archived = Set(defaults.array(forKey: key) as? [String] ?? [])
        if value {
            archived.insert(id.uuidString)
        } else {
            archived.remove(id.uuidString)
        }
        defaults.set(Array(archived), forKey: key)
    }

    public static func archivedIDs(in defaults: UserDefaults = .standard) -> Set<UUID> {
        let raw = defaults.array(forKey: key) as? [String] ?? []
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
