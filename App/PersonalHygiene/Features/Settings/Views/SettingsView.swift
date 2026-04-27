import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var focusScheduleStore: (any FocusScheduleStore)?
    var diagnosticsActions: DiagnosticsActions?

    @Environment(\.modelContext) private var modelContext

    @AppStorage(SnoozeDurationStore.key) private var snoozeMinutes = SnoozeDurationStore.defaultMinutes

    @State private var backupExport: BackupExport?
    @State private var showingImporter = false
    @State private var backupError: String?
    @State private var showingWhatsNew = false
    @State private var showingOnboardingRestartConfirm = false
    @State private var rescheduleShiftMinutes: Int = 30

    private struct BackupExport: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        // No `NavigationStack` here on purpose: when this view lives inside
        // the iOS 18 TabView "More" overflow tab, the system already wraps
        // the overflow in its own NavigationStack. Adding a second stack
        // produced two back chevrons stacked vertically when pushing into
        // Diagnostics / FocusSchedule. The standalone preview supplies its
        // own stack so the NavigationLink + navigationTitle still work.
        List {
            if let error = viewModel.lastError {
                Section {
                    ErrorBanner(message: error, onDismiss: { viewModel.lastError = nil })
                }
            }
            notificationsSection
            schedulingSection

            HomeLocationSection()
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

            Stepper(
                value: $rescheduleShiftMinutes,
                in: -120...120,
                step: 15
            ) {
                HStack {
                    Text("settings.reschedule.shift", bundle: .main)
                    Spacer()
                    Text(LocalizedStringResource("settings.reschedule.shift.value \(rescheduleShiftMinutes)"))
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                let shift = rescheduleShiftMinutes
                Task { await viewModel.rescheduleToday(shiftedByMinutes: shift) }
            } label: {
                Text("settings.reschedule.action", bundle: .main)
            }
            .disabled(viewModel.status != .authorized && viewModel.status != .provisional)
        } header: {
            Text("settings.section.scheduling", bundle: .main)
        } footer: {
            Text("settings.reschedule.footer", bundle: .main)
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
            if let diagnosticsActions {
                NavigationLink {
                    DiagnosticsView(viewModel: viewModel, actions: diagnosticsActions)
                } label: {
                    Label {
                        Text("settings.diagnostics.title", bundle: .main)
                    } icon: {
                        Image(systemName: "stethoscope")
                    }
                }
            }
        } header: {
            Text("settings.section.about", bundle: .main)
        } footer: {
            Text(verbatim: BuildInfo.shortDescriptor)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
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
