import SwiftUI

/// Round-27 follow-up: home-location settings now default to
/// auto-detection via `HomeLocationDetector` (CoreLocation + reverse
/// geocoding). User toggles to manual entry to use the same
/// autocomplete + map preview the trip destination uses.
///
/// Backed by `HomeLocationStore` (UserDefaults) — auto-detected
/// coordinates and the manual override land in the same fields, so
/// downstream consumers (`MKDirectionsTravelTimeService`,
/// `TripCarbonSection`) keep working unchanged.
struct HomeLocationSection: View {

    @AppStorage(HomeLocationStore.isSetKey) private var homeIsSet = false
    @AppStorage(HomeLocationStore.nameKey) private var homeName = ""
    @AppStorage(HomeLocationStore.latitudeKey) private var homeLatitude = 0.0
    @AppStorage(HomeLocationStore.longitudeKey) private var homeLongitude = 0.0
    /// Round-27: default = auto-detect on. User can flip to manual entry.
    @AppStorage("settings.home.autoDetect") private var autoDetect = true

    @State private var detector = HomeLocationDetector()
    @State private var manualLat: Double?
    @State private var manualLng: Double?

    var body: some View {
        Section {
            Toggle(isOn: $autoDetect) {
                Label {
                    Text("settings.home.auto.toggle", bundle: .main)
                } icon: {
                    Image(systemName: "location.fill")
                }
            }
            .onChange(of: autoDetect) { _, isOn in
                if isOn {
                    detector.detect()
                }
            }

            if autoDetect {
                autoDetectContent
            } else {
                manualContent
            }

            if homeIsSet {
                DestinationMapPreview(
                    name: homeName,
                    latitude: homeLatitude,
                    longitude: homeLongitude
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        } header: {
            Text("settings.section.home", bundle: .main)
        } footer: {
            Text("settings.section.home.footer", bundle: .main)
        }
        .onAppear {
            if autoDetect, !homeIsSet {
                detector.detect()
            }
            manualLat = homeIsSet ? homeLatitude : nil
            manualLng = homeIsSet ? homeLongitude : nil
        }
        .onChange(of: detector.status) { _, newStatus in
            if case .ready(let name, let lat, let lng) = newStatus, autoDetect {
                homeName = name
                homeLatitude = lat
                homeLongitude = lng
                homeIsSet = true
            }
        }
    }

    @ViewBuilder
    private var autoDetectContent: some View {
        switch detector.status {
        case .idle, .requestingAuth, .detecting:
            HStack(spacing: 8) {
                ProgressView()
                Text("settings.home.auto.detecting", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .ready:
            if !homeName.isEmpty {
                LabeledContent {
                    Text(verbatim: homeName)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                } label: {
                    Text("settings.home.auto.detected", bundle: .main)
                }
            }
            Button {
                detector.detect()
            } label: {
                Label {
                    Text("settings.home.auto.refresh", bundle: .main)
                } icon: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        case .denied:
            VStack(alignment: .leading, spacing: 4) {
                Text("settings.home.auto.denied", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.red)
                Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                    Text("settings.notifications.action.openSettings", bundle: .main)
                        .font(.caption)
                }
            }
        case .failed(let message):
            Text(verbatim: message)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var manualContent: some View {
        let nameBinding = Binding<String>(
            get: { homeName },
            set: { newValue in
                homeName = newValue
                if let lat = manualLat, let lng = manualLng, !newValue.isEmpty {
                    homeLatitude = lat
                    homeLongitude = lng
                    homeIsSet = true
                }
            }
        )
        LocationAutocompleteField(
            name: nameBinding,
            latitude: $manualLat,
            longitude: $manualLng,
            label: "settings.home.field.name",
            placeholder: "settings.home.field.name.placeholder"
        )
        .onChange(of: manualLat) { _, _ in commitManualIfReady() }
        .onChange(of: manualLng) { _, _ in commitManualIfReady() }
    }

    private func commitManualIfReady() {
        guard let lat = manualLat, let lng = manualLng else { return }
        homeLatitude = lat
        homeLongitude = lng
        homeIsSet = true
    }
}
