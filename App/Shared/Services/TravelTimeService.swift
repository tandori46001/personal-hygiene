import Foundation

#if canImport(MapKit)
import MapKit
#endif

/// Mode of transport used to estimate the travel time between two locations.
public enum TravelMode: String, Sendable, Codable, CaseIterable {
    case automobile
    case walking
    case transit
}

public enum TravelTimeError: Error, Equatable {
    case noRouteFound
    case unavailable
}

/// Estimates how long it takes to travel between two locations.
///
/// Conformers must be safe to call from any actor; the protocol is `Sendable`
/// so it can be passed into `NotificationFactory.notifications(...)`.
public protocol TravelTimeService: Sendable {
    func estimatedTravelTime(
        from origin: BlockLocation,
        to destination: BlockLocation,
        mode: TravelMode
    ) async throws -> TimeInterval
}

/// Test / preview implementation that returns canned values. Look-up by
/// `(origin, destination)` pair; falls back to `defaultTravelTime` when the
/// pair isn't registered.
public struct StaticTravelTimeService: TravelTimeService {

    public struct RoutePair: Hashable, Sendable {
        public let origin: BlockLocation
        public let destination: BlockLocation

        public init(origin: BlockLocation, destination: BlockLocation) {
            self.origin = origin
            self.destination = destination
        }
    }

    public let defaultTravelTime: TimeInterval
    public let overrides: [RoutePair: TimeInterval]

    public init(
        defaultTravelTime: TimeInterval = 0,
        overrides: [RoutePair: TimeInterval] = [:]
    ) {
        self.defaultTravelTime = defaultTravelTime
        self.overrides = overrides
    }

    public func estimatedTravelTime(
        from origin: BlockLocation,
        to destination: BlockLocation,
        mode _: TravelMode
    ) async throws -> TimeInterval {
        let pair = RoutePair(origin: origin, destination: destination)
        return overrides[pair] ?? defaultTravelTime
    }
}

#if canImport(MapKit)

/// Production implementation that asks `MKDirections` for the fastest route's
/// expected travel time. Stateless — safe to share across actors.
public final class MKDirectionsTravelTimeService: TravelTimeService, @unchecked Sendable {

    public init() {}

    public func estimatedTravelTime(
        from origin: BlockLocation,
        to destination: BlockLocation,
        mode: TravelMode
    ) async throws -> TimeInterval {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = mode.mkTransportType

        let response = try await MKDirections(request: request).calculate()
        guard let fastest = response.routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) else {
            throw TravelTimeError.noRouteFound
        }
        return fastest.expectedTravelTime
    }
}

extension TravelMode {
    fileprivate var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .automobile: return .automobile
        case .walking: return .walking
        case .transit: return .transit
        }
    }
}

#endif
