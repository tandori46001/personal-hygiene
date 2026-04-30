import SwiftUI

/// Round 35 IA redesign: trip-global preferences extracted from per-trip
/// detail views, so the user sets them once and every trip respects the
/// choice. The carbon footprint unit (kg vs. lb) was already
/// `@AppStorage`-backed — its picker just lived inside `TripCarbonSection`,
/// which made it look per-trip even though changing it on trip A also
/// flipped trip B. Moving the picker here aligns the UI with the storage.
///
/// Storage key (`trip.carbon.unit`) is unchanged; existing values
/// preserved on first launch after the move.
struct TravelPreferencesSection: View {

    @AppStorage("trip.carbon.unit") private var carbonUnit: String = "kg"

    var body: some View {
        Section {
            Picker(selection: $carbonUnit) {
                Text("trip.carbon.unit.kg", bundle: .main).tag("kg")
                Text("trip.carbon.unit.lb", bundle: .main).tag("lb")
            } label: {
                Label {
                    Text("settings.travelPrefs.unit.label", bundle: .main)
                } icon: {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("settings.travelPrefs.title", bundle: .main)
        } footer: {
            Text("settings.travelPrefs.unit.footer", bundle: .main)
        }
    }
}
