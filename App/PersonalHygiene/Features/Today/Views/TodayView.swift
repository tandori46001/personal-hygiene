import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel

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
                                BlockTimelineRow(block: block)
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

    var body: some View {
        HStack {
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.title)
                    .font(.body)
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
            Text("\(block.durationMinutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func formattedTime(minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}
