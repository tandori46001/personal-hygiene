import Foundation

/// Round-16: a small palette of SF Symbols paired with a friendly label so
/// the housekeeping room picker can render an icon next to the name. Pure
/// value-type lookup — caller stores the SF Symbol name as a string on
/// `HousekeepingRoomIconStore`.
public enum HousekeepingRoomIcons {

    public struct IconChoice: Sendable, Equatable, Identifiable {
        public let id: String  // SF Symbol name
        public let displayKey: String

        public init(id: String, displayKey: String) {
            self.id = id
            self.displayKey = displayKey
        }
    }

    public static let palette: [IconChoice] = [
        IconChoice(id: "bed.double", displayKey: "housekeeping.icon.bedroom"),
        IconChoice(id: "fork.knife", displayKey: "housekeeping.icon.kitchen"),
        IconChoice(id: "shower", displayKey: "housekeeping.icon.bathroom"),
        IconChoice(id: "sofa", displayKey: "housekeeping.icon.living"),
        IconChoice(id: "washer", displayKey: "housekeeping.icon.laundry"),
        IconChoice(id: "tray.full", displayKey: "housekeeping.icon.storage"),
        IconChoice(id: "house", displayKey: "housekeeping.icon.house"),
        IconChoice(id: "leaf", displayKey: "housekeeping.icon.outdoor"),
    ]

    public static func choice(forID id: String) -> IconChoice? {
        palette.first { $0.id == id }
    }
}

public enum HousekeepingRoomIconStore {

    public static let key = "housekeeping.roomIcons"

    public static func dictionary(defaults: UserDefaults = .standard) -> [String: String] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    public static func iconID(forRoom room: String, defaults: UserDefaults = .standard) -> String? {
        dictionary(defaults: defaults)[room]
    }

    public static func setIconID(_ id: String?, forRoom room: String, in defaults: UserDefaults = .standard) {
        var current = dictionary(defaults: defaults)
        if let id, !id.isEmpty {
            current[room] = id
        } else {
            current.removeValue(forKey: room)
        }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: key)
        }
    }
}
