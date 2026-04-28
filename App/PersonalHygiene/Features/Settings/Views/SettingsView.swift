import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var focusScheduleStore: (any FocusScheduleStore)?
    var diagnosticsActions: DiagnosticsActions?
    /// Round-17 wire: optional routine repository so the Focus schedule
    /// screen can preview which blocks would be silenced right now.
    var routineRepository: (any RoutineRepository)?

    @Environment(\.modelContext) private var modelContext

    @AppStorage(SnoozeDurationStore.key) private var snoozeMinutes = SnoozeDurationStore.defaultMinutes
    @AppStorage(MedicationFollowUpDelayStore.key)
    private var followUpMinutes = MedicationFollowUpDelayStore.defaultMinutes
    @AppStorage("settings.theme") var themeOverride: String = "system"
    @AppStorage(MarineForecastFreshnessStore.key)
    var marineHours = MarineForecastFreshnessStore.defaultHours
    @State private var showingPauseSheet = false

    @State private var backupExport: BackupExport?
    @State var showingImporter = false
    @State var backupError: String?
    @State var showingWhatsNew = false
    @State var showingOnboardingRestartConfirm = false
    @State private var rescheduleShiftMinutes: Int = 30
    @State private var showingRescheduleConfirm = false
    @State var showingResetCustomizationsConfirm = false

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

            categoryMuteSection
            pauseSection
            quietHoursSection
            themeSection
            HomeLocationSection()
            if let focusScheduleStore {
                Section {
                    NavigationLink {
                        FocusScheduleView(
                            store: focusScheduleStore,
                            blocksProvider: {
                                guard let repository = routineRepository else { return [] }
                                return (try? repository.allTemplates().flatMap(\.blocks)) ?? []
                            }
                        )
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
            backupAutoFrequencySection
            moodLogSection
            round22Sections
            round23Sections
            round24Sections
            everythingBundleRow
            resetOnboardingTipsRow
            aboutFooterSection
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
        .confirmationDialog(
            Text("settings.reset.allCustomizations.confirm.title", bundle: .main),
            isPresented: $showingResetCustomizationsConfirm,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                resetAllCustomizations()
            } label: {
                Text("settings.reset.allCustomizations.confirm.action", bundle: .main)
            }
            Button(role: .cancel) {} label: {
                Text("common.cancel", bundle: .main)
            }
        } message: {
            Text("settings.reset.allCustomizations.confirm.message", bundle: .main)
        }
        .confirmationDialog(
            Text("settings.reschedule.confirm.title \(rescheduleShiftMinutes)", bundle: .main),
            isPresented: $showingRescheduleConfirm,
            titleVisibility: .visible
        ) {
            Button {
                let shift = rescheduleShiftMinutes
                Task { await viewModel.rescheduleToday(shiftedByMinutes: shift) }
            } label: {
                Text("settings.reschedule.confirm.action", bundle: .main)
            }
            Button(role: .cancel) {} label: {
                Text("common.cancel", bundle: .main)
            }
        } message: {
            Text("settings.reschedule.confirm.message", bundle: .main)
        }
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
                    Text(localizedKey: "settings.snooze.duration.\(minutes)")
                        .tag(minutes)
                }
            } label: {
                Text("settings.snooze.duration.label", bundle: .main)
            }

            Picker(selection: $followUpMinutes) {
                ForEach(MedicationFollowUpDelayStore.allowedMinutes, id: \.self) { minutes in
                    Text(localizedKey: "settings.medication.followup.\(minutes)")
                        .tag(minutes)
                }
            } label: {
                Text("settings.medication.followup.label", bundle: .main)
            }
            .accessibilityHint(Text("settings.medication.followup.hint", bundle: .main))

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
                showingRescheduleConfirm = true
            } label: {
                Text("settings.reschedule.action", bundle: .main)
            }
            .disabled(viewModel.status != .authorized && viewModel.status != .provisional)

            if let count = viewModel.lastRescheduleCount {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("settings.reschedule.toast.\(count)", bundle: .main)
                        .font(.caption)
                    Spacer()
                    Button {
                        viewModel.clearLastRescheduleCount()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("common.dismiss", bundle: .main))
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text("settings.section.scheduling", bundle: .main)
        } footer: {
            Text("settings.reschedule.footer", bundle: .main)
        }
    }

    func resetAllCustomizations() {
        SnoozeDurationStore.set(SnoozeDurationStore.defaultMinutes, in: .standard)
        MedicationFollowUpDelayStore.set(MedicationFollowUpDelayStore.defaultMinutes, in: .standard)
        snoozeMinutes = SnoozeDurationStore.defaultMinutes
        followUpMinutes = MedicationFollowUpDelayStore.defaultMinutes
        themeOverride = "system"
        marineHours = MarineForecastFreshnessStore.defaultHours
        UserDefaults.standard.removeObject(forKey: PreferredAdvisorySourceStore.key)
        UserDefaults.standard.removeObject(forKey: HomeLocationStore.isSetKey)
        UserDefaults.standard.removeObject(forKey: HomeLocationStore.latitudeKey)
        UserDefaults.standard.removeObject(forKey: HomeLocationStore.longitudeKey)
        UserDefaults.standard.removeObject(forKey: HomeLocationStore.nameKey)
        UserDefaults.standard.removeObject(forKey: PauseNotificationsStore.key)
        UserDefaults.standard.removeObject(forKey: HotWeatherStore.enabledKey)
        UserDefaults.standard.removeObject(forKey: HotWeatherStore.bumpKey)
        UserDefaults.standard.removeObject(forKey: MarineForecastFreshnessStore.key)
        NotificationCategoryMuteStore.clearAll()
        PerBlockFollowUpOverrideStore.clearAll()
        focusScheduleStore?.removeAll()
    }

    func exportBackup() {
        backupError = nil
        do {
            // Round-19 slice T3.11: bundle the most recent diagnostics
            // snapshot inside the backup file so a single share covers
            // user data + the diagnostics one-pager.
            let latestDiagnostics = SnapshotHistoryStore.snapshots().first
            let snapshot = try BackupService.export(
                from: modelContext,
                diagnostics: latestDiagnostics
            )
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
