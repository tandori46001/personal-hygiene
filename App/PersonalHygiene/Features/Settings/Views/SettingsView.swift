import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    @AppStorage(HomeLocationStore.isSetKey) private var homeIsSet = false
    @AppStorage(HomeLocationStore.nameKey) private var homeName = ""
    @AppStorage(HomeLocationStore.latitudeKey) private var homeLatitude = 0.0
    @AppStorage(HomeLocationStore.longitudeKey) private var homeLongitude = 0.0

    @State private var homeLatitudeText = ""
    @State private var homeLongitudeText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("settings.notifications.status", bundle: .main)
                        Spacer()
                        Text(localizedStatus(viewModel.status))
                            .foregroundStyle(.secondary)
                    }
                    if viewModel.status == .notDetermined {
                        Button {
                            Task { await viewModel.requestPermission() }
                        } label: {
                            Text("settings.notifications.action.request", bundle: .main)
                        }
                    } else if viewModel.status == .denied {
                        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                            Text("settings.notifications.action.openSettings", bundle: .main)
                        }
                    }
                } header: {
                    Text("settings.section.notifications", bundle: .main)
                }

                Section {
                    Button {
                        Task { await viewModel.refreshNotifications() }
                    } label: {
                        Text("settings.notifications.action.refresh", bundle: .main)
                    }
                    .disabled(viewModel.status != .authorized && viewModel.status != .provisional)

                    if let last = viewModel.lastRefreshAt {
                        Text(
                            LocalizedStringResource(
                                "settings.notifications.lastRefresh \(last.formatted(date: .omitted, time: .shortened))"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("settings.section.scheduling", bundle: .main)
                }

                homeSection
            }
            .navigationTitle(Text("settings.title", bundle: .main))
            .task { await viewModel.reloadStatus() }
            .onAppear { hydrateHomeFromStore() }
        }
    }

    @ViewBuilder
    private var homeSection: some View {
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
            .onChange(of: homeLatitudeText) { _, _ in commitHomeLocation() }
            .onChange(of: homeName) { _, _ in commitHomeLocation() }

            TextField(
                text: $homeLongitudeText,
                prompt: Text(verbatim: "0.000000")
            ) {
                Text("settings.home.field.longitude", bundle: .main)
            }
            .keyboardType(.numbersAndPunctuation)
            .autocorrectionDisabled()
            .onChange(of: homeLongitudeText) { _, _ in commitHomeLocation() }

            if !isHomeValid {
                Text("settings.home.invalid", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("settings.section.home", bundle: .main)
        } footer: {
            Text("settings.section.home.footer", bundle: .main)
        }
    }

    private var isHomeValid: Bool {
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

    private func hydrateHomeFromStore() {
        if homeIsSet {
            if homeLatitudeText.isEmpty { homeLatitudeText = String(format: "%.6f", homeLatitude) }
            if homeLongitudeText.isEmpty { homeLongitudeText = String(format: "%.6f", homeLongitude) }
        }
    }

    private func commitHomeLocation() {
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

    private func localizedStatus(_ status: NotificationAuthorizationStatus) -> LocalizedStringKey {
        switch status {
        case .authorized: return "settings.notifications.status.authorized"
        case .provisional: return "settings.notifications.status.provisional"
        case .denied: return "settings.notifications.status.denied"
        case .ephemeral: return "settings.notifications.status.ephemeral"
        case .notDetermined: return "settings.notifications.status.notDetermined"
        }
    }
}
