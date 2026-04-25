import CoreLocation
import Foundation

/// A geographic location attached to a `Block`. Pure value type so it can be
/// constructed in tests and serialized without dragging in MapKit.
public struct BlockLocation: Equatable, Hashable, Sendable, Codable {
    public let latitude: Double
    public let longitude: Double
    public let displayName: String?

    public init(latitude: Double, longitude: Double, displayName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.displayName = displayName
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var isValid: Bool {
        CLLocationCoordinate2DIsValid(coordinate)
    }
}
