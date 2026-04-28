import SwiftUI
import SwiftData

/// Round-21 slice T3.17: aggregates carbon estimates across all trips ending
/// within the trailing 30 days into a single "footprint" Settings section.
/// Uses the same `TripCarbonEstimate.TransportMode` raw values surfaced in
/// `TripCarbonSection` so the per-trip mode preference flows through.
struct SettingsFootprintSummaryView: View {

    let trips: [Trip]
    let homeLocation: BlockLocation?

    @AppStorage("trip.carbon.unit") private var unit: String = "kg"
    @AppStorage("trip.carbon.mode") private var modeRaw: String = "flight"

    private var mode: TripCarbonEstimate.TransportMode {
        TripCarbonEstimate.TransportMode(rawValue: modeRaw) ?? .flight
    }

    private var summary: TripFootprintAggregator.Summary {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = trips.filter { $0.endDate >= cutoff }
        let contributions: [TripFootprintAggregator.TripContribution] = recent.compactMap { trip in
            guard let lat = trip.destinationLatitude,
                  let lon = trip.destinationLongitude,
                  let homeLat = homeLocation?.latitude,
                  let homeLon = homeLocation?.longitude
            else { return nil }
            let distance = TripCarbonEstimate.distanceKm(
                fromLat: homeLat,
                fromLon: homeLon,
                toLat: lat,
                toLon: lon
            )
            let kg = TripCarbonEstimate.roundTripKgCO2(distanceKm: distance, mode: mode)
            return TripFootprintAggregator.TripContribution(kgCO2: kg, mode: mode)
        }
        return TripFootprintAggregator.summary(from: contributions)
    }

    var body: some View {
        let snapshot = summary
        if snapshot.tripCount > 0 {
            Section {
                LabeledContent {
                    Text(verbatim: formattedValue(snapshot.totalKgCO2))
                        .font(.body.monospacedDigit())
                } label: {
                    Text("settings.footprint.total", bundle: .main)
                }
                LabeledContent {
                    Text(verbatim: "\(snapshot.tripCount)")
                        .font(.callout.monospacedDigit())
                } label: {
                    Text("settings.footprint.trips", bundle: .main)
                }
            } header: {
                Text("settings.footprint.title", bundle: .main)
            } footer: {
                Text("settings.footprint.footer", bundle: .main)
            }
        }
    }

    private func formattedValue(_ kg: Double) -> String {
        switch unit {
        case "lb":
            let lb = kg * 2.2046226218
            return String(format: "%.1f lb CO₂", lb)
        default:
            return String(format: "%.1f kg CO₂", kg)
        }
    }
}
