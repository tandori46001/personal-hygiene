import Foundation

/// Reads / writes the user's home location from `UserDefaults`. Used as the
/// origin for travel-time notifications.
///
/// Coordinates are stored as plain `Double`s (with 0 = unset, gated by the
/// boolean flag) so `@AppStorage` can bind directly without sentinels.
public struct HomeLocationStore {

    public static let isSetKey = "home.isSet"
    public static let latitudeKey = "home.latitude"
    public static let longitudeKey = "home.longitude"
    public static let nameKey = "home.name"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var location: BlockLocation? {
        guard defaults.bool(forKey: Self.isSetKey) else { return nil }
        let lat = defaults.double(forKey: Self.latitudeKey)
        let lon = defaults.double(forKey: Self.longitudeKey)
        let name = defaults.string(forKey: Self.nameKey)
        let candidate = BlockLocation(
            latitude: lat,
            longitude: lon,
            displayName: (name?.isEmpty == false) ? name : nil
        )
        return candidate.isValid ? candidate : nil
    }
}
