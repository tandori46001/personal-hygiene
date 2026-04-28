import Foundation

/// Round-14 slice 13: rough carbon footprint estimate based on a one-way
/// distance × CO₂ factor. Pure value type — caller passes the haversine
/// distance and a transport mode; we just multiply. Factors are public-domain
/// industry averages — not authoritative; the UI labels output as "rough
/// estimate" so the user knows.
///
/// Round-19 slice T4.16: ferry + public-transport factors added so the
/// estimate isn't flight-only. Source: UK DEFRA 2023 conversion factors
/// (passenger-km basis). Numbers are rounded to 3 decimals.
public enum TripCarbonEstimate {

    public enum TransportMode: String, CaseIterable, Sendable {
        case flight
        case ferry
        case publicTransport
        case car

        /// kg CO₂ equivalent emitted per passenger per kilometer.
        public var kgPerPassengerKm: Double {
            switch self {
            case .flight: 0.255
            case .ferry: 0.115
            case .publicTransport: 0.041
            case .car: 0.171
            }
        }
    }

    public static let economyKgPerPassengerKm: Double = TransportMode.flight.kgPerPassengerKm

    /// Haversine distance in km between two lat/lon coords.
    public static func distanceKm(
        fromLat: Double,
        fromLon: Double,
        toLat: Double,
        toLon: Double
    ) -> Double {
        let earthRadiusKm = 6_371.0
        let dLat = (toLat - fromLat) * .pi / 180
        let dLon = (toLon - fromLon) * .pi / 180
        let lat1 = fromLat * .pi / 180
        let lat2 = toLat * .pi / 180
        let aTerm = sin(dLat / 2) * sin(dLat / 2)
            + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
        let cTerm = 2 * atan2(aTerm.squareRoot(), (1 - aTerm).squareRoot())
        return earthRadiusKm * cTerm
    }

    /// Round-trip CO₂ in kg for the given one-way distance + transport mode.
    public static func roundTripKgCO2(
        distanceKm: Double,
        mode: TransportMode = .flight
    ) -> Double {
        max(0, distanceKm) * 2 * mode.kgPerPassengerKm
    }
}
