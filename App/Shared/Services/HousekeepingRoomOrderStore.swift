import Foundation

/// Round-12 slice 33: persists the user's preferred drag-to-reorder order for
/// housekeeping rooms. Stored as a sorted array of room name strings. Rooms
/// not present in the persisted order fall to the bottom in their original
/// alphabetical order so newly-added rooms surface at the end, not lost.
public enum HousekeepingRoomOrderStore {

    public static let key = "housekeeping.roomOrder"

    public static func order(defaults: UserDefaults = .standard) -> [String] {
        defaults.array(forKey: key) as? [String] ?? []
    }

    public static func set(_ rooms: [String], in defaults: UserDefaults = .standard) {
        defaults.set(rooms, forKey: key)
    }

    public static func sorted(_ rooms: [String], defaults: UserDefaults = .standard) -> [String] {
        let saved = order(defaults: defaults)
        guard !saved.isEmpty else { return rooms.sorted() }
        let known = saved.filter { rooms.contains($0) }
        let extra = rooms.filter { !saved.contains($0) }.sorted()
        return known + extra
    }
}
