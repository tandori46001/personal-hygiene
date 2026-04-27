import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel
    var onCreateTemplate: (() -> Void)?

    @State private var showingProgressDetail = false
    @State private var nowMinutes: Int = Self.currentMinutesFromMidnight()
    @State private var detailBlock: Block?
    @State private var categoryFilter: BlockCategory?
    @State private var showingResetDayConfirm = false
    @State private var refreshToast: String?
    @AppStorage("today.compactMode") private var compactMode = false
    @Environment(\.scenePhase) private var scenePhase

    /// Round-12 slice 23: filter shown blocks by the selected category. `nil`
    /// shows everything (default).
    private func visibleBlocks(_ blocks: [Block]) -> [Block] {
        guard let categoryFilter else { return blocks }
        return blocks.filter { $0.category == categoryFilter }
    }

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

                        if !template.sortedBlocks.isEmpty {
                            Section {
                                CategoryFilterChips(selected: $categoryFilter, blocks: template.sortedBlocks)
                            }
                        }

                        Section {
                            ForEach(visibleBlocks(template.sortedBlocks)) { block in
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
                                .contextMenu {
                                    Button {
                                        viewModel.toggleDone(block)
                                    } label: {
                                        Label {
                                            Text(
                                                viewModel.isDone(block)
                                                    ? "today.action.markUndone"
                                                    : "today.action.markDone",
                                                bundle: .main
                                            )
                                        } icon: {
                                            Image(systemName: "checkmark.circle")
                                        }
                                    }
                                    Button {
                                        viewModel.toggleSkippedToday(block)
                                    } label: {
                                        Label {
                                            Text(
                                                viewModel.isSkipped(block)
                                                    ? "today.action.unskipToday"
                                                    : "today.action.skipToday",
                                                bundle: .main
                                            )
                                        } icon: {
                                            Image(systemName: "moon.zzz")
                                        }
                                    }
                                    Button {
                                        detailBlock = block
                                    } label: {
                                        Label {
                                            Text("today.action.details", bundle: .main)
                                        } icon: {
                                            Image(systemName: "info.circle")
                                        }
                                    }
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
                    Menu {
                        Button {
                            compactMode.toggle()
                        } label: {
                            Label {
                                Text(
                                    compactMode ? "today.compact.disable" : "today.compact.enable",
                                    bundle: .main
                                )
                            } icon: {
                                Image(systemName: compactMode
                                    ? "list.bullet.rectangle.fill"
                                    : "list.bullet.rectangle")
                            }
                        }
                        Button(role: .destructive) {
                            showingResetDayConfirm = true
                        } label: {
                            Label {
                                Text("today.action.resetDay", bundle: .main)
                            } icon: {
                                Image(systemName: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(Text("today.action.menu", bundle: .main))
                }
            }
            .refreshable {
                viewModel.reload()
                nowMinutes = Self.currentMinutesFromMidnight()
                refreshToast = String(localized: "today.refresh.done")
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                refreshToast = nil
            }
            .confirmationDialog(
                Text("today.resetDay.confirm.title", bundle: .main),
                isPresented: $showingResetDayConfirm,
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    viewModel.resetDay()
                } label: {
                    Text("today.resetDay.confirm.action", bundle: .main)
                }
                Button(role: .cancel) {} label: {
                    Text("common.cancel", bundle: .main)
                }
            } message: {
                Text("today.resetDay.confirm.message", bundle: .main)
            }
            .overlay(alignment: .top) {
                if let toast = refreshToast {
                    Text(verbatim: toast)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 8)
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
