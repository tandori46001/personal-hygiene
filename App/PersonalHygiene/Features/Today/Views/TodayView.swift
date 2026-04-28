import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel
    var onCreateTemplate: (() -> Void)?

    @State private var showingProgressDetail = false
    @State private var nowMinutes: Int = Self.currentMinutesFromMidnight()
    @State private var detailBlock: Block?
    @State private var categoryFilter: BlockCategory?
    @State var showingResetDayConfirm = false
    @State private var refreshToast: String?
    @State var resetDaySnapshot: TodayViewModel.ResetDaySnapshot?
    @State var resetDayUndoTimer: Task<Void, Never>?
    @State private var minuteTickTimer: Task<Void, Never>?
    /// Round-18 slice 5: visible after the device time zone changes mid-session
    /// (e.g. landing in another country) so the user knows Today's day boundary
    /// shifted under their feet. User dismisses by tapping the row.
    @State var staleDayBannerVisible = false
    @AppStorage("today.compactMode") var compactMode = false
    @AppStorage("today.collapseDone") var collapseDoneBlocks = false
    @Environment(\.scenePhase) private var scenePhase

    static func currentMinutesFromMidnight(
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    /// Round-13 slice 7: keep `nowMinutes` fresh every 60s while the view is
    /// foregrounded — wraps the static factory so view body stays compact.
    func startMinuteTicker() {
        minuteTickTimer?.cancel()
        minuteTickTimer = Self.makeMinuteTicker { [self] in
            self.nowMinutes = Self.currentMinutesFromMidnight()
        }
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
                    ScrollViewReader { proxy in
                    List {
                        staleDayBannerSection
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
                            let visible = visibleBlocks(
                                template.sortedBlocks,
                                filter: categoryFilter,
                                collapseDone: collapseDoneBlocks
                            )
                            ForEach(visible) { block in
                                if shouldInsertNowMarker(
                                    before: block,
                                    in: template.sortedBlocks,
                                    nowMinutes: nowMinutes
                                ) {
                                    NowMarkerRow(nowMinutes: nowMinutes) {
                                        // Round-20 slice T4.17: tap → snap back
                                        // to the current/next block.
                                        if let target = viewModel.currentBlock() ?? viewModel.nextBlock() {
                                            withAnimation { proxy.scrollTo(target.id, anchor: .center) }
                                        }
                                    }
                                }
                                BlockTimelineRow(
                                    block: block,
                                    isDone: viewModel.isDone(block),
                                    isSkipped: viewModel.isSkipped(block),
                                    isSnoozedToday: viewModel.isSnoozedToday(block),
                                    compact: compactMode,
                                    onToggle: { viewModel.toggleDone(block) }
                                )
                                .id(block.id) // Round-20 slice T4.17: ScrollViewReader anchor.
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
                        moodQuickLogSection
                        tomorrowSection
                    }
                    } // ScrollViewReader (round-20 slice T4.17)
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
            .toolbar { todayToolbar }
            .refreshable {
                viewModel.reload()
                nowMinutes = Self.currentMinutesFromMidnight()
                refreshToast = Self.composedRefreshToast()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                refreshToast = nil
            }
            .confirmationDialog(
                Text("today.resetDay.confirm.title", bundle: .main),
                isPresented: $showingResetDayConfirm,
                titleVisibility: .visible
            ) {
                Button(role: .destructive) {
                    let snapshot = viewModel.resetDay()
                    if !snapshot.isEmpty {
                        resetDaySnapshot = snapshot
                        scheduleResetDayUndoExpiry()
                    }
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
            .overlay(alignment: .bottom) { resetDayUndoOverlay }
            .onAppear {
                viewModel.reload()
                nowMinutes = Self.currentMinutesFromMidnight()
                startMinuteTicker()
            }
            .onDisappear {
                minuteTickTimer?.cancel()
                minuteTickTimer = nil
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    nowMinutes = Self.currentMinutesFromMidnight()
                    viewModel.reload()
                    startMinuteTicker()
                } else {
                    minuteTickTimer?.cancel()
                    minuteTickTimer = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
                viewModel.reload()
                nowMinutes = Self.currentMinutesFromMidnight()
                staleDayBannerVisible = true
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
