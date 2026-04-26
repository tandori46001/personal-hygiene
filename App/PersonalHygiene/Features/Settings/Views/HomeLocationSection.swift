import SwiftUI

/// Settings sub-section that lets the user configure their home coordinates,
/// used by `MKDirectionsTravelTimeService` to compute travel-time padding for
/// notification leads. Extracted out of `SettingsView` to keep that struct
/// under SwiftLint's `type_body_length` limit.
struct HomeLocationSection: View {

    @AppStorage(HomeLocationStore.isSetKey) private var homeIsSet = false
    @AppStorage(HomeLocationStore.nameKey) private var homeName = ""
    @AppStorage(HomeLocationStore.latitudeKey) private var homeLatitude = 0.0
    @AppStorage(HomeLocationStore.longitudeKey) private var homeLongitude = 0.0

    @State private var homeLatitudeText = ""
    @State private var homeLongitudeText = ""

    var body: some View {
        Section {
            TextField(
                text: $homeName,
                prompt: Text("settings.home.field.name.placeholder", bundle: .main)
            ) {
                Text("settings.home.field.name", bundle: .main)
            }
            .textInputAutocapitalization(.words)

            TextField(
                text: $homeLatitudeText,
                prompt: Text(verbatim: "0.000000")
            ) {
                Text("settings.home.field.latitude", bundle: .main)
            }
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled()
            .onChange(of: homeLatitudeText) { _, _ in commit() }
            .onChange(of: homeName) { _, _ in commit() }

            TextField(
                text: $homeLongitudeText,
                prompt: Text(verbatim: "0.000000")
            ) {
                Text("settings.home.field.longitude", bundle: .main)
            }
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled()
            .onChange(of: homeLongitudeText) { _, _ in commit() }

            if !isValid {
                Text("settings.home.invalid", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("settings.section.home", bundle: .main)
        } footer: {
            Text("settings.section.home.footer", bundle: .main)
        }
        .onAppear { hydrate() }
    }

    private var isValid: Bool {
        let latStr = homeLatitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lonStr = homeLongitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if latStr.isEmpty && lonStr.isEmpty { return true }
        guard
            let lat = Double(latStr.replacingOccurrences(of: ",", with: ".")),
            let lon = Double(lonStr.replacingOccurrences(of: ",", with: "."))
        else {
            return false
        }
        return BlockLocation(latitude: lat, longitude: lon).isValid
    }

    private func hydrate() {
        if homeIsSet {
            if homeLatitudeText.isEmpty { homeLatitudeText = String(format: "%.6f", homeLatitude) }
            if homeLongitudeText.isEmpty { homeLongitudeText = String(format: "%.6f", homeLongitude) }
        }
    }

    private func commit() {
        let latStr = homeLatitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lonStr = homeLongitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if latStr.isEmpty && lonStr.isEmpty {
            homeIsSet = false
            return
        }
        guard
            let lat = Double(latStr.replacingOccurrences(of: ",", with: ".")),
            let lon = Double(lonStr.replacingOccurrences(of: ",", with: "."))
        else {
            homeIsSet = false
            return
        }
        let candidate = BlockLocation(latitude: lat, longitude: lon)
        guard candidate.isValid else {
            homeIsSet = false
            return
        }
        homeLatitude = lat
        homeLongitude = lon
        homeIsSet = true
    }
}
