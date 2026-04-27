import Foundation

/// Round-13 slice 33: per-contact relationship tag (family / friend /
/// coworker / other). Filterable in BirthdaysView.
public enum BirthdayRelationship: String, Sendable, CaseIterable, Codable {
    case family
    case friend
    case coworker
    case other

    public var systemImage: String {
        switch self {
        case .family: "house"
        case .friend: "heart"
        case .coworker: "briefcase"
        case .other: "person"
        }
    }
}

public enum BirthdayRelationshipStore {

    public static let key = "birthdays.relationships"

    public static func dictionary(defaults: UserDefaults = .standard) -> [String: BirthdayRelationship] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        let raw = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        return raw.compactMapValues { BirthdayRelationship(rawValue: $0) }
    }

    public static func relationship(
        for contactID: String,
        defaults: UserDefaults = .standard
    ) -> BirthdayRelationship {
        dictionary(defaults: defaults)[contactID] ?? .other
    }

    public static func set(
        _ value: BirthdayRelationship?,
        for contactID: String,
        in defaults: UserDefaults = .standard
    ) {
        var raw = dictionary(defaults: defaults).mapValues { $0.rawValue }
        if let value, value != .other {
            raw[contactID] = value.rawValue
        } else {
            raw.removeValue(forKey: contactID)
        }
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: key)
        }
    }

    public static func clear(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
