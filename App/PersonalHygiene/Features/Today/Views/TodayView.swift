import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel

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
                                ProgressSummaryRow(
                                    done: viewModel.doneCount,
                                    total: viewModel.totalCount
                                )
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
                                    onToggle: { viewModel.toggleDone(block) }
                                )
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
                    }
                }
            }
            .navigationTitle(Text("today.title", bundle: .main))
            .onAppear { viewModel.reload() }
        }
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
        }
        .accessibilityElement(children: .combine)
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

private struct BlockTimelineRow: View {
    let block: Block
    let isDone: Bool
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

            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.title)
                    .font(.body)
                    .strikethrough(isDone, color: .secondary)
                Text(LocalizedStringKey("category.\(block.category.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}
