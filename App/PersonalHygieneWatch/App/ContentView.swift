import SwiftData
import SwiftUI
import WatchKit
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    /// Round-19: mirror the iPhone `settings.theme` AppStorage via the App
    /// Group suite so a user toggle on the phone propagates to the watch
    /// without a redeploy. Falls back to the watch's standard defaults until
    /// the App Group entitlement ships.
    @AppStorage(
        "settings.theme",
        store: UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    )
    private var themeOverride: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch themeOverride {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some View {
        let repository = SwiftDataRoutineRepository(context: modelContext)
        let snoozeStore = UserDefaultsBlockSnoozeStore()
        let skipStore = UserDefaultsBlockSkipStore()
        TodayWatchView(
            viewModel: TodayViewModel(
                repository: repository,
                skipStore: skipStore,
                snoozeStore: snoozeStore
            ),
            repository: repository
        )
        .preferredColorScheme(preferredColorScheme)
    }
}

struct TodayWatchView: View {
    @Bindable var viewModel: TodayViewModel
    let repository: any RoutineRepository

    @State private var doneBlockIDs: Set<UUID> = []
    @State private var errorMessage: String?
    /// Round-21 slice T5.29: most-recently-toggled block id, used to surface
    /// a 3-second "Undo" overlay so a wrist mis-tap is recoverable without
    /// opening the iPhone app.
    @State private var pendingUndoID: UUID?
    @State private var undoExpiryTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.activeTemplate == nil {
                    ContentUnavailableView {
                        Label {
                            Text("watch.today.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    } description: {
                        Text("watch.today.empty.description", bundle: .main)
                    }
                } else {
                    List {
                        if let current = viewModel.currentBlock() {
                            Section {
                                row(for: current, highlighted: true)
                            } header: {
                                Text("today.now", bundle: .main)
                            }
                        } else if let next = viewModel.nextBlock() {
                            Section {
                                row(for: next, highlighted: true)
                            } header: {
                                Text("today.next", bundle: .main)
                            }
                        }

                        Section {
                            ForEach(viewModel.blocks) { block in
                                NavigationLink {
                                    BlockDetailWatchView(
                                        block: block,
                                        isDone: doneBlockIDs.contains(block.id),
                                        isSkipped: viewModel.isSkipped(block),
                                        onToggleDone: { toggleDone(block) },
                                        onToggleSkip: {
                                            viewModel.toggleSkippedToday(block)
                                            viewModel.reload()
                                        },
                                        onSkipRestOfDay: {
                                            viewModel.skipRestOfToday(from: block)
                                            viewModel.reload()
                                        }
                                    )
                                } label: {
                                    WatchBlockRow(
                                        block: block,
                                        highlighted: false,
                                        isDone: doneBlockIDs.contains(block.id),
                                        isSnoozedToday: viewModel.isSnoozedToday(block)
                                    )
                                }
                            }
                        } header: {
                            Text("today.section.schedule", bundle: .main)
                        }

                        Section {
                            NavigationLink {
                                SettingsGlanceWatchView()
                            } label: {
                                Label {
                                    Text("watch.settings.title", bundle: .main)
                                } icon: {
                                    Image(systemName: "gearshape")
                                }
                            }
                            NavigationLink {
                                HydrationGlanceWatchView()
                            } label: {
                                Label {
                                    Text("watch.hydration.title", bundle: .main)
                                } icon: {
                                    Image(systemName: "drop.fill")
                                }
                            }
                            NavigationLink {
                                MoodQuickLogWatchView()
                            } label: {
                                Label {
                                    Text("watch.mood.title", bundle: .main)
                                } icon: {
                                    Image(systemName: "face.smiling")
                                }
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let undoID = pendingUndoID {
                    HStack(spacing: 6) {
                        Text("watch.undo.label", bundle: .main)
                            .font(.caption2)
                        Button {
                            if let block = viewModel.blocks.first(where: { $0.id == undoID }) {
                                toggleDone(block)
                            }
                            pendingUndoID = nil
                            undoExpiryTask?.cancel()
                        } label: {
                            Text("common.undo", bundle: .main)
                                .font(.caption2.bold())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 4)
                }
            }
            .navigationTitle(Text("today.title", bundle: .main))
            .onAppear {
                viewModel.reload()
                refreshDoneSet()
            }
            .onChange(of: scenePhase) { _, phase in
                // Watch dozes between glances; when the user wakes the watch we
                // re-pull the schedule + done set so the snooze badge mirrored
                // from iPhone reflects whatever the user did on the phone in
                // the meantime. We also force a widget timeline reload so the
                // NextBlock complication picks up any iPhone-side changes
                // immediately instead of waiting for the system's next refresh.
                if phase == .active {
                    viewModel.reload()
                    refreshDoneSet()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }

    @ViewBuilder
    private func row(for block: Block, highlighted: Bool) -> some View {
        Button {
            toggleDone(block)
        } label: {
            WatchBlockRow(
                block: block,
                highlighted: highlighted,
                isDone: doneBlockIDs.contains(block.id),
                isSnoozedToday: viewModel.isSnoozedToday(block)
            )
        }
        .buttonStyle(.plain)
    }

    private func refreshDoneSet() {
        do {
            let completions = try repository.completions(on: Date(), calendar: .autoupdatingCurrent)
            doneBlockIDs = Set(completions.map(\.blockID))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleDone(_ block: Block) {
        do {
            if doneBlockIDs.contains(block.id) {
                try repository.unmarkDone(block, on: Date(), calendar: .autoupdatingCurrent)
                doneBlockIDs.remove(block.id)
            } else {
                try repository.markDone(block, on: Date(), calendar: .autoupdatingCurrent)
                doneBlockIDs.insert(block.id)
            }
            // Round-21 slice T5.29: success haptic + 3-second undo capsule.
            WKInterfaceDevice.current().play(.success)
            pendingUndoID = block.id
            undoExpiryTask?.cancel()
            undoExpiryTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    pendingUndoID = nil
                }
            }
            // The NextBlock complication renders the upcoming block; toggling
            // done here invalidates that, so force a timeline reload instead
            // of waiting for the system's next scheduled refresh.
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SettingsGlanceWatchView: View {
    @State private var authStatus: NotificationAuthorizationStatus = .notDetermined
    @State private var pauseSummary: String = ""

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.suiteName) ?? .standard
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("watch.settings.snoozeDuration", bundle: .main)
                    Spacer()
                    let mins = SnoozeDurationStore.minutes(defaults: sharedDefaults)
                    Text(localizedKey: "settings.snooze.duration.\(mins)")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } header: {
                Text("watch.settings.section.snooze", bundle: .main)
            } footer: {
                Text("watch.settings.snooze.footer", bundle: .main)
            }

            Section {
                HStack {
                    Text("watch.settings.notifications", bundle: .main)
                    Spacer()
                    Text(localizedStatus(authStatus))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                if !pauseSummary.isEmpty {
                    HStack {
                        Text("watch.settings.pause.label", bundle: .main)
                        Spacer()
                        Text(verbatim: pauseSummary)
                            .foregroundStyle(.orange)
                            .font(.caption.monospacedDigit())
                    }
                    .accessibilityElement(children: .combine)
                }
                // Round-23 slice T5.27: 1-hour pause toggle from the wrist.
                Button {
                    PauseNotificationsStore.pauseForHours(1, in: sharedDefaults)
                    pauseSummary = computePauseSummary(now: Date())
                } label: {
                    Label {
                        Text("watch.settings.pause.action.1h", bundle: .main)
                    } icon: {
                        Image(systemName: "pause.circle")
                    }
                }
                if !pauseSummary.isEmpty {
                    Button(role: .destructive) {
                        PauseNotificationsStore.clear(in: sharedDefaults)
                        pauseSummary = ""
                    } label: {
                        Label {
                            Text("watch.settings.pause.action.resume", bundle: .main)
                        } icon: {
                            Image(systemName: "play.circle")
                        }
                    }
                }
            } header: {
                Text("watch.settings.section.notifications", bundle: .main)
            }

            Section {
                Text(verbatim: BuildInfo.shortDescriptor)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } header: {
                Text("watch.settings.section.about", bundle: .main)
            }

            // Round-24 slice T6.33: pending hydration reset (mirrors the
            // iPhone-side reconciler).
            let pending = WatchHydrationGlanceStore.pendingTaps(in: sharedDefaults)
            if !pending.isEmpty {
                Section {
                    Button(role: .destructive) {
                        WatchHydrationGlanceStore.clearPending(in: sharedDefaults)
                    } label: {
                        Label {
                            Text("watch.settings.hydration.resetPending \(pending.count)", bundle: .main)
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                } footer: {
                    Text("watch.settings.hydration.resetPending.footer", bundle: .main)
                }
            }

            // Round-22 slice T6.33: 7-day mood strip mirrored from the
            // iPhone Today view — gives the wearer a quick read of mood
            // history without opening the iPhone app.
            let strip = WatchMoodStrip.cells(
                defaults: sharedDefaults
            )
            if strip.contains(where: { $0.symbol != "·" }) {
                Section {
                    HStack(spacing: 4) {
                        ForEach(strip, id: \.day) { cell in
                            Text(verbatim: cell.symbol)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("watch.settings.section.moodStrip", bundle: .main)
                }
            }
        }
        .navigationTitle(Text("watch.settings.title", bundle: .main))
        .task {
            authStatus = await UserNotificationsService().authorizationStatus()
            pauseSummary = computePauseSummary(now: Date())
        }
    }

    /// Round-19 slice T2.8: mirror the iOS pause-notifications state on the
    /// watch glance. Reads `PauseNotificationsStore` via the App Group suite
    /// (falls back to `.standard` until the entitlement ships) so a pause
    /// triggered on the phone shows up here without a watch-side toggle.
    private func computePauseSummary(now: Date) -> String {
        let defaults = sharedDefaults
        guard PauseNotificationsStore.isPaused(now: now, defaults: defaults),
              let until = PauseNotificationsStore.pausedUntil(defaults: defaults)
        else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: until)
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

// `BlockDetailWatchView` lives in `BlockDetailWatchView.swift` (round 23 T7).

private struct WatchBlockRow: View {
    let block: Block
    let highlighted: Bool
    let isDone: Bool
    var isSnoozedToday: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? .green : .secondary)
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(block.title)
                .font(highlighted ? .headline : .body)
                .strikethrough(isDone)
                .lineLimit(2)
            Spacer(minLength: 0)
            if isSnoozedToday {
                Image(systemName: "alarm")
                    .foregroundStyle(.blue)
                    .font(.caption2)
                    .accessibilityLabel(Text("today.snoozedToday", bundle: .main))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

#Preview {
    // swiftlint:disable:next force_try
    ContentView().modelContainer(try! AppModelContainer.makeInMemory())
}
