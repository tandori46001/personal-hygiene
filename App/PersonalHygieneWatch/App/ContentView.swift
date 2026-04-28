import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

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
    }
}

struct TodayWatchView: View {
    @Bindable var viewModel: TodayViewModel
    let repository: any RoutineRepository

    @State private var doneBlockIDs: Set<UUID> = []
    @State private var errorMessage: String?
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
                        }
                    }
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

    var body: some View {
        List {
            Section {
                HStack {
                    Text("watch.settings.snoozeDuration", bundle: .main)
                    Spacer()
                    Text(LocalizedStringResource(
                        "settings.snooze.duration.\(SnoozeDurationStore.minutes())"
                    ))
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
        }
        .navigationTitle(Text("watch.settings.title", bundle: .main))
        .task {
            authStatus = await UserNotificationsService().authorizationStatus()
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

private struct BlockDetailWatchView: View {
    let block: Block
    let isDone: Bool
    let isSkipped: Bool
    let onToggleDone: () -> Void
    let onToggleSkip: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(block.title)
                    .font(.headline)
                Label {
                    Text(localizedKey: "category.\(block.category.rawValue)")
                } icon: {
                    Image(systemName: "tag")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Label {
                    Text(verbatim: formattedTime(minutes: block.startMinutesFromMidnight))
                        + Text(verbatim: " · \(block.durationMinutes) min")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                Button {
                    onToggleDone()
                    dismiss()
                } label: {
                    Label {
                        Text(
                            isDone
                                ? "today.action.unmarkDone"
                                : "today.action.markDone",
                            bundle: .main
                        )
                    } icon: {
                        Image(systemName: isDone ? "arrow.uturn.backward" : "checkmark.circle")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSkipped)

                Button(role: .destructive) {
                    onToggleSkip()
                    dismiss()
                } label: {
                    Label {
                        Text(
                            isSkipped
                                ? "today.action.unskipToday"
                                : "today.action.skipToday",
                            bundle: .main
                        )
                    } icon: {
                        Image(systemName: "moon.zzz")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(Text("watch.detail.title", bundle: .main))
    }

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

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
