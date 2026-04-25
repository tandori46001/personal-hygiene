import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let repository = SwiftDataRoutineRepository(context: modelContext)
        TodayWatchView(viewModel: TodayViewModel(repository: repository))
    }
}

struct TodayWatchView: View {
    @Bindable var viewModel: TodayViewModel

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
                                WatchBlockRow(block: current, highlighted: true)
                            } header: {
                                Text("today.now", bundle: .main)
                            }
                        } else if let next = viewModel.nextBlock() {
                            Section {
                                WatchBlockRow(block: next, highlighted: true)
                            } header: {
                                Text("today.next", bundle: .main)
                            }
                        }

                        Section {
                            ForEach(viewModel.blocks) { block in
                                WatchBlockRow(block: block, highlighted: false)
                            }
                        } header: {
                            Text("today.section.schedule", bundle: .main)
                        }
                    }
                }
            }
            .navigationTitle(Text("today.title", bundle: .main))
            .onAppear { viewModel.reload() }
        }
    }
}

private struct WatchBlockRow: View {
    let block: Block
    let highlighted: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(formattedTime(minutes: block.startMinutesFromMidnight))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Text(block.title)
                .font(highlighted ? .headline : .body)
                .lineLimit(2)
            Spacer(minLength: 0)
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
