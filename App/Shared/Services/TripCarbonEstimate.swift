import Foundation

/// Round-14 slice 13: rough carbon footprint estimate based on a one-way
/// flight distance × CO₂ factor. Pure value type — caller passes the
/// haversine distance and the factor; we just multiply. The factor used
/// (0.255 kg CO₂ per km per passenger) is a public-domain industry average
/// for short-medium haul economy class. Not authoritative — surfaced as
/// "rough estimate" in the UI so the user knows.
public enum TripCarbonEstimate {

    public static let economyKgPerPassengerKm: Double = 0.255

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

    /// Round-trip CO₂ in kg for the given one-way distance.
    public static func roundTripKgCO2(distanceKm: Double) -> Double {
        max(0, distanceKm) * 2 * economyKgPerPassengerKm
    }
}
