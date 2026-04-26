import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let repository = SwiftDataRoutineRepository(context: modelContext)
        let snoozeStore = UserDefaultsBlockSnoozeStore()
        TodayWatchView(
            viewModel: TodayViewModel(repository: repository, snoozeStore: snoozeStore),
            repository: repository
        )
    }
}

struct TodayWatchView: View {
    @Bindable var viewModel: TodayViewModel
    let repository: any RoutineRepository

    @State private var doneBlockIDs: Set<UUID> = []
    @State private var errorMessage: String?

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
                                row(for: block, highlighted: false)
                            }
                        } header: {
                            Text("today.section.schedule", bundle: .main)
                        }
                    }
                }
            }
            .navigationTitle(Text("today.title", bundle: .main))
            .onAppear {
                viewModel.reload()
                refreshDoneSet()
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
        } catch {
            errorMessage = error.localizedDescription
        }
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
