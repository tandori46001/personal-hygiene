import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel
    var onCreateTemplate: (() -> Void)?

    @State private var showingProgressDetail = false
    @State private var nowMinutes: Int = Self.currentMinutesFromMidnight()
    @State private var detailBlock: Block?
    @AppStorage("today.compactMode") private var compactMode = false
    @Environment(\.scenePhase) private var scenePhase

    static func currentMinutesFromMidnight(
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func shouldInsertNowMarker(before block: Block, in blocks: [Block]) -> Bool {
        guard let first = blocks.first, let last = blocks.last else { return false }
        let scheduleEnd = last.startMinutesFromMidnight + last.durationMinutes
        guard nowMinutes >= first.startMinutesFromMidnight, nowMinutes < scheduleEnd else {
            return false
        }
        // Insert before the first block whose start is strictly after `nowMinutes`.
        guard let target = blocks.first(where: { $0.startMinutesFromMidnight > nowMinutes }) else {
            return false
        }
        return block.id == target.id
    }

    @ViewBuilder
    private var tripCountdownSection: some View {
        if let trip = viewModel.upcomingTrip, let days = viewModel.daysUntilUpcomingTrip() {
            Section {
                TripCountdownRow(trip: trip, daysUntil: days)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let template = viewModel.activeTemplate {
                    List {
                        if let focus = viewModel.activeFocusWindow() {
                            Section {
                                FocusActiveBanner(window: focus)
                            }
                        }
                        tripCountdownSection
                        if viewModel.totalCount > 0 {
                            Section {
                                Button {
                                    showingProgressDetail = true
                                } label: {
                                    ProgressSummaryRow(
                                        done: viewModel.doneCount,
                                        total: viewModel.totalCount,
                                        nextBlock: viewModel.nextBlock()
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("today.summary.tapHint", bundle: .main))
                            }
                        }
                        if let current = viewModel.currentBlock() {
                            Section {
                                BlockNowRow(
                                    block: current,
                                    label: Text("today.now", bundle: .main),
                                    minutesUntilStart: nil
                                )
                            }
                        } else if let next = viewModel.nextBlock() {
                            let until = max(0, next.startMinutesFromMidnight - nowMinutes)
                            Section {
                                BlockNowRow(
                                    block: next,
                                    label: Text("today.next", bundle: .main),
                                    minutesUntilStart: until
                                )
                            }
                        }

                        Section {
                            ForEach(template.sortedBlocks) { block in
                                if shouldInsertNowMarker(before: block, in: template.sortedBlocks) {
                                    NowMarkerRow(nowMinutes: nowMinutes)
                                }
                                BlockTimelineRow(
                                    block: block,
                                    isDone: viewModel.isDone(block),
                                    isSkipped: viewModel.isSkipped(block),
                                    isSnoozedToday: viewModel.isSnoozedToday(block),
                                    compact: compactMode,
                                    onToggle: { viewModel.toggleDone(block) }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    detailBlock = block
                                }
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        viewModel.toggleSkippedToday(block)
                                    } label: {
                                        if viewModel.isSkipped(block) {
                                            Label {
                                                Text("today.action.unskipToday", bundle: .main)
                                            } icon: {
                                                Image(systemName: "arrow.uturn.backward.circle")
                                            }
                                        } else {
                                            Label {
                                                Text("today.action.skipToday", bundle: .main)
                                            } icon: {
                                                Image(systemName: "moon.zzz")
                                            }
                                        }
                                    }
                                    .tint(.orange)
                                    if !viewModel.isSkipped(block) {
                                        Button {
                                            viewModel.skipRestOfToday(from: block)
                                        } label: {
                                            Label {
                                                Text("today.action.skipRest", bundle: .main)
                                            } icon: {
                                                Image(systemName: "forward.end")
                                            }
                                        }
                                        .tint(.red)
                                    }
                                }
                            }
                        } header: {
                            Text("today.section.schedule", bundle: .main)
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label {
                            Text("today.empty.title", bundle: .main)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    } description: {
                        Text("today.empty.description", bundle: .main)
                    } actions: {
                        if let onCreateTemplate {
                            Button(action: onCreateTemplate) {
                                Label {
                                    Text("today.empty.action.createTemplate", bundle: .main)
                                } icon: {
                                    Image(systemName: "plus")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle(Text("today.title", bundle: .main))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        compactMode.toggle()
                    } label: {
                        Image(systemName: compactMode ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                    }
                    .accessibilityLabel(Text(
                        compactMode ? "today.compact.disable" : "today.compact.enable",
                        bundle: .main
                    ))
                }
            }
            .onAppear {
                viewModel.reload()
                nowMinutes = Self.currentMinutesFromMidnight()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    nowMinutes = Self.currentMinutesFromMidnight()
                    viewModel.reload()
                }
            }
            .sheet(isPresented: $showingProgressDetail) {
                if let template = viewModel.activeTemplate {
                    ProgressDetailSheet(blocks: template.sortedBlocks, isDone: viewModel.isDone)
                }
            }
            .sheet(item: $detailBlock) { block in
                BlockDetailSheet(
                    block: block,
                    isDone: viewModel.isDone(block),
                    isSkipped: viewModel.isSkipped(block),
                    onToggleDone: { viewModel.toggleDone(block) },
                    onToggleSkip: { viewModel.toggleSkippedToday(block) }
                )
            }
        }
    }
}

private struct ProgressDetailSheet: View {

    let blocks: [Block]
    let isDone: (Block) -> Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(blocks) { block in
                HStack {
                    Image(systemName: isDone(block) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isDone(block) ? Color.green : Color.secondary)
                        .accessibilityHidden(true)
                    Text(block.title)
                        .strikethrough(isDone(block), color: .secondary)
                        .foregroundStyle(isDone(block) ? .secondary : .primary)
                    Spacer()
                    Text(formattedTime(minutes: block.startMinutesFromMidnight))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            .navigationTitle(Text("today.summary.detail.title", bundle: .main))
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

    private func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

private struct TripCountdownRow: View {
    let trip: Trip
    let daysUntil: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane")
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.name)
                    .font(.headline)
                if daysUntil == 0 {
                    Text("today.trip.departingToday", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("today.trip.daysUntil.\(daysUntil)", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(verbatim: trip.destinationName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProgressSummaryRow: View {
    let done: Int
    let total: Int
    let nextBlock: Block?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: done == total ? "checkmark.circle.fill" : "circle.dotted")
                .foregroundStyle(done == total ? Color.green : Color.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("today.summary.title.\(done).\(total)", bundle: .main)
                    .font(.headline)
                ProgressView(value: Double(done), total: Double(max(total, 1)))
                    .progressViewStyle(.linear)
                if let nextBlock {
                    Text("today.summary.nextPreview \(formattedTime(nextBlock)) \(nextBlock.title)", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("today.summary.dayDone", bundle: .main)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedTime(_ block: Block) -> String {
        let hour = block.startMinutesFromMidnight / 60
        let minute = block.startMinutesFromMidnight % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

private struct FocusActiveBanner: View {
    let window: DeepFocusFilter.FocusWindow

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.purple)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("today.focus.active", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(window.blockTitle)
                    .font(.headline)
            }
            Spacer()
            Text(window.end, format: .dateTime.hour().minute())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct BlockNowRow: View {
    let block: Block
    let label: Text
    let minutesUntilStart: Int?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                label
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(block.title)
                    .font(.title3)
                    .bold()
                Text(LocalizedStringKey("category.\(block.category.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let until = minutesUntilStart {
                    Text(Self.untilCaption(minutes: until), bundle: .main)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                }
            }
            Spacer()
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.title2, design: .monospaced))
                .accessibilityLabel(spokenTime(minutes: block.startMinutesFromMidnight))
        }
        .accessibilityElement(children: .combine)
    }

    /// Round-11: human-friendly "in N min" / "in 1h N min" / "now" caption
    /// for the upcoming block. Returns a localization key with `%lld` slots
    /// so EN/ES/FR formats can vary independently.
    static func untilCaption(minutes: Int) -> LocalizedStringKey {
        if minutes <= 0 { return "today.next.startingNow" }
        if minutes < 60 { return "today.next.inMinutes.\(minutes)" }
        let hours = minutes / 60
        let rem = minutes % 60
        if rem == 0 { return "today.next.inHours.\(hours)" }
        return "today.next.inHoursAndMinutes \(hours) \(rem)"
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func spokenTime(minutes: Int) -> Text {
        let hour = minutes / 60
        let minute = minutes % 60
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = Calendar.autoupdatingCurrent.date(from: components) {
            return Text(date, format: .dateTime.hour().minute())
        }
        return Text(verbatim: formattedTime(minutes: minutes))
    }
}
