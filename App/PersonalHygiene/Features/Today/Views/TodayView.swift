import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel
    var onCreateTemplate: (() -> Void)?

    @State private var showingProgressDetail = false

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
                                        total: viewModel.totalCount
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("today.summary.tapHint", bundle: .main))
                            }
                        }
                        if let current = viewModel.currentBlock() {
                            Section {
                                BlockNowRow(block: current, label: Text("today.now", bundle: .main))
                            }
                        } else if let next = viewModel.nextBlock() {
                            Section {
                                BlockNowRow(block: next, label: Text("today.next", bundle: .main))
                            }
                        }

                        Section {
                            ForEach(template.sortedBlocks) { block in
                                BlockTimelineRow(
                                    block: block,
                                    isDone: viewModel.isDone(block),
                                    isSkipped: viewModel.isSkipped(block),
                                    isSnoozedToday: viewModel.isSnoozedToday(block),
                                    onToggle: { viewModel.toggleDone(block) }
                                )
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
            .onAppear { viewModel.reload() }
            .sheet(isPresented: $showingProgressDetail) {
                if let template = viewModel.activeTemplate {
                    ProgressDetailSheet(blocks: template.sortedBlocks, isDone: viewModel.isDone)
                }
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
            }
        }
        .accessibilityElement(children: .combine)
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
            }
            Spacer()
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.title2, design: .monospaced))
                .accessibilityLabel(spokenTime(minutes: block.startMinutesFromMidnight))
        }
        .accessibilityElement(children: .combine)
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

private struct BlockTimelineRow: View {
    let block: Block
    let isDone: Bool
    let isSkipped: Bool
    let isSnoozedToday: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isDone
                    ? Text("today.action.unmarkDone", bundle: .main)
                    : Text("today.action.markDone", bundle: .main)
            )
            .disabled(isSkipped)

            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
                .accessibilityLabel(spokenTime(minutes: block.startMinutesFromMidnight))
            BlockCategoryDot(category: block.category)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.title)
                    .font(.body)
                    .strikethrough(isDone || isSkipped, color: .secondary)
                Text(LocalizedStringKey("category.\(block.category.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSnoozedToday {
                Image(systemName: "alarm")
                    .foregroundStyle(.blue)
                    .accessibilityLabel(Text("today.snoozedToday", bundle: .main))
            }
            if isSkipped {
                Image(systemName: "moon.zzz")
                    .foregroundStyle(.orange)
                    .accessibilityLabel(Text("today.action.skipToday", bundle: .main))
            }
            if block.isDeepFocus {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.purple)
                    .accessibilityLabel(Text("today.focus.deep", bundle: .main))
            }
            Text(verbatim: "\(block.durationMinutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .opacity(isSkipped ? 0.6 : 1.0)
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func spokenTime(minutes: Int) -> Text {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        if let date = Calendar.autoupdatingCurrent.date(from: components) {
            return Text(date, format: .dateTime.hour().minute())
        }
        return Text(verbatim: formattedTime(minutes: minutes))
    }
}
