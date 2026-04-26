import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var focusScheduleStore: (any FocusScheduleStore)?

    @Environment(\.modelContext) private var modelContext

    @AppStorage(HomeLocationStore.isSetKey) private var homeIsSet = false
    @AppStorage(HomeLocationStore.nameKey) private var homeName = ""
    @AppStorage(HomeLocationStore.latitudeKey) private var homeLatitude = 0.0
    @AppStorage(HomeLocationStore.longitudeKey) private var homeLongitude = 0.0

    @AppStorage(SnoozeDurationStore.key) private var snoozeMinutes = SnoozeDurationStore.defaultMinutes

    @State private var homeLatitudeText = ""
    @State private var homeLongitudeText = ""

    @State private var backupExport: BackupExport?
    @State private var showingImporter = false
    @State private var backupError: String?
    @State private var showingWhatsNew = false
    @State private var showingOnboardingRestartConfirm = false

    private struct BackupExport: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        NavigationStack {
            List {
                if let error = viewModel.lastError {
                    Section {
                        ErrorBanner(message: error, onDismiss: { viewModel.lastError = nil })
                    }
                }
                notificationsSection
                schedulingSection

                homeSection
                if let focusScheduleStore {
                    Section {
                        NavigationLink {
                            FocusScheduleView(store: focusScheduleStore)
                        } label: {
                            Label {
                                Text("settings.focus.entry", bundle: .main)
                            } icon: {
                                Image(systemName: "moon.zzz")
                            }
                        }
                    } header: {
                        Text("settings.section.focus", bundle: .main)
                    }
                }
                aboutSection
                backupSection
            }
            .navigationTitle(Text("settings.title", bundle: .main))
            .task { await viewModel.reloadStatus() }
            .onAppear { hydrateHomeFromStore() }
            .sheet(item: $backupExport) { exp in
                ShareSheet(items: [exp.url])
            }
            .sheet(isPresented: $showingWhatsNew) {
                WhatsNewSheet()
            }
            .confirmationDialog(
                Text("settings.onboarding.restart.confirm.title", bundle: .main),
                isPresented: $showingOnboardingRestartConfirm,
                titleVisibility: .visible,
                actions: { onboardingRestartActions }
            )
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
    }

    @ViewBuilder
    private var onboardingRestartActions: some View {
        Button(role: .destructive) {
            OnboardingFlagStore.reset()
        } label: {
            Text("settings.onboarding.restart.confirm.action", bundle: .main)
        }
        Button(role: .cancel) {} label: {
            Text("common.cancel", bundle: .main)
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section {
            HStack {
                Text("settings.notifications.status", bundle: .main)
                Spacer()
                Text(localizedStatus(viewModel.status))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
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
    }

    @ViewBuilder
    private var schedulingSection: some View {
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

            Picker(selection: $snoozeMinutes) {
                ForEach(SnoozeDurationStore.allowedMinutes, id: \.self) { minutes in
                    Text(LocalizedStringResource("settings.snooze.duration.\(minutes)"))
                        .tag(minutes)
                }
            } label: {
                Text("settings.snooze.duration.label", bundle: .main)
            }
        } header: {
            Text("settings.section.scheduling", bundle: .main)
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            Button {
                showingWhatsNew = true
            } label: {
                Label {
                    Text("settings.about.whatsNew", bundle: .main)
                } icon: {
                    Image(systemName: "sparkles")
                }
            }
            Button {
                showingOnboardingRestartConfirm = true
            } label: {
                Label {
                    Text("settings.onboarding.restart", bundle: .main)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        } header: {
            Text("settings.section.about", bundle: .main)
        }
    }

    @ViewBuilder
    private var backupSection: some View {
        Section {
            Button {
                exportBackup()
            } label: {
                Label {
                    Text("settings.backup.action.export", bundle: .main)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            Button(role: .destructive) {
                showingImporter = true
            } label: {
                Label {
                    Text("settings.backup.action.import", bundle: .main)
                } icon: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            if let backupError {
                Text(verbatim: backupError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("settings.section.backup", bundle: .main)
        } footer: {
            Text("settings.section.backup.footer", bundle: .main)
        }
    }

    private func exportBackup() {
        backupError = nil
        do {
            let snapshot = try BackupService.export(from: modelContext)
            let data = try BackupService.encode(snapshot)
            let filename = "personal-hygiene-backup-\(Int(Date().timeIntervalSince1970)).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            backupExport = BackupExport(url: url)
        } catch {
            backupError = error.localizedDescription
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        backupError = nil
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let snapshot = try BackupService.decode(data)
            try BackupService.restore(snapshot, into: modelContext)
        } catch {
            backupError = error.localizedDescription
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

private struct WhatsNewSheet: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                tip(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "onboarding.tip.widget.title",
                    body: "onboarding.tip.widget.body"
                )
                tip(
                    systemImage: "mic.fill",
                    title: "onboarding.tip.siri.title",
                    body: "onboarding.tip.siri.body"
                )
                tip(
                    systemImage: "bell.badge.fill",
                    title: "onboarding.tip.notifications.title",
                    body: "onboarding.tip.notifications.body"
                )
            }
            .navigationTitle(Text("settings.about.whatsNew", bundle: .main))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("common.done", bundle: .main)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tip(systemImage: String, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title, bundle: .main)
                    .font(.headline)
                Text(body, bundle: .main)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
