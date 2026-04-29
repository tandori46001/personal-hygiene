import SwiftData
import SwiftUI

struct TodayView: View {
    @Bindable var viewModel: TodayViewModel
    var onCreateTemplate: (() -> Void)?

    /// Round-26 fix: SwiftData `@Query` is a reactive observer of the
    /// modelContext. It auto-refreshes whenever any RoutineTemplate is
    /// inserted, deleted, or updated — bypassing both the repository
    /// fetch path (which proved unreliable across tab switches) and the
    /// `viewModel.activeTemplate` cache. Computed `activeTemplate` reads
    /// directly from this query and the body's `if let` re-evaluates as
    /// soon as `isActive` flips on any template.
    @Query(sort: \RoutineTemplate.name) private var allTemplates: [RoutineTemplate]

    /// L008 reapplied: trips also need a reactive observer of the
    /// modelContext, otherwise the upcoming-trip section disappears
    /// across tab switches the same way the active-template did before
    /// the round-26 fix. Computed `upcomingTrip` reads directly here.
    @Query(sort: \Trip.startDate) private var allTrips: [Trip]

    /// Round 27 WS-B: important days are SwiftData-backed (cross-tab via
    /// @Query). Birthdays come from the iOS Contacts framework — read-only,
    /// async, loaded into `viewModel.upcomingBirthdays` on appear /
    /// scenePhase active. No L008 risk because the data source is the OS,
    /// not another tab.
    @Query private var allImportantDays: [ImportantDay]
    @AppStorage("today.showBirthdays") private var showBirthdays = true
    @AppStorage("today.showImportantDays") private var showImportantDays = true

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

    /// Round-26 fix: compute the active template directly from the
    /// reactive `@Query`. `viewModel.activeTemplate` stays kept in sync
    /// via `.onAppear` / `.onChange` so the rest of the VM (currentBlock,
    /// nextBlock, blocks, etc.) keeps working. Today's day type is
    /// re-derived each render so a midnight crossover updates without
    /// needing a manual reload.
    private var queriedActiveTemplate: RoutineTemplate? {
        let dayType = TodayViewModel.dayType(for: Date(), in: .autoupdatingCurrent)
        return allTemplates.first { $0.dayType == dayType && $0.isActive }
    }

    private var queriedUpcomingTrip: Trip? {
        TodayViewModel.nextUpcoming(
            trips: allTrips,
            now: Date(),
            calendar: .autoupdatingCurrent
        )
    }

    private func daysUntilQueriedUpcomingTrip() -> Int? {
        guard let trip = queriedUpcomingTrip else { return nil }
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: trip.startDate)
        return calendar.dateComponents([.day], from: today, to: target).day
    }

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
        if let trip = queriedUpcomingTrip, let days = daysUntilQueriedUpcomingTrip() {
            Section {
                TripCountdownRow(trip: trip, daysUntil: days)
            }
        }
    }

    /// Round 27 WS-B B1: birthdays of contacts that fall today or within
    /// the user's lead-default window. Section hides itself if empty or
    /// disabled in Settings. Source: `viewModel.upcomingBirthdays`,
    /// async-loaded from Contacts on appear / scenePhase active.
    @ViewBuilder
    private var birthdaysSection: some View {
        if showBirthdays, !viewModel.upcomingBirthdays.isEmpty {
            Section {
                ForEach(viewModel.upcomingBirthdays, id: \.contact.identifier) { entry in
                    BirthdayTodayRow(entry: entry)
                }
            } header: {
                Text("today.section.birthdays", bundle: .main)
            }
        }
    }

    /// Round 27 WS-B B6: locale-seeded + custom important days that match
    /// today or fall within the fixed 7-day window (user requested
    /// "a partir de una semana antes del evento"). Hidden if empty or
    /// disabled in Settings.
    @ViewBuilder
    private var importantDaysSection: some View {
        if showImportantDays {
            let now = Date()
            let entries = ImportantDayResolver.upcoming(
                days: allImportantDays.filter(\.enabled),
                on: now,
                windowDays: TodayViewModel.todayImportantDaysLeadDays
            )
            if !entries.isEmpty {
                Section {
                    ForEach(entries, id: \.id) { entry in
                        ImportantDayRow(entry: entry)
                    }
                } header: {
                    Text("today.section.importantDays", bundle: .main)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let template = queriedActiveTemplate {
                    ScrollViewReader { proxy in
                    List {
                        staleDayBannerSection
                        if let focus = viewModel.activeFocusWindow() {
                            Section {
                                FocusActiveBanner(window: focus)
                            }
                        }
                        tripCountdownSection
                        birthdaysSection
                        importantDaysSection
                        progressSummarySection(showingDetail: $showingProgressDetail)
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
                // Round-26 fix: push @Query result into VM so the rest of
                // the VM logic (currentBlock, nextBlock, completion set)
                // sees the right activeTemplate.
                viewModel.activeTemplate = queriedActiveTemplate
                viewModel.reload()
                nowMinutes = Self.currentMinutesFromMidnight()
                startMinuteTicker()
                // Round 27 WS-B B1: async-load birthdays from Contacts.
                Task { await viewModel.reloadBirthdays() }
            }
            .onChange(of: queriedActiveTemplate?.id) { _, _ in
                // Round-26 fix: when SwiftData reports a different active
                // template (user activated one in another tab), push the
                // new value into the VM and re-derive its caches.
                viewModel.activeTemplate = queriedActiveTemplate
                viewModel.reload()
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
                    Task { await viewModel.reloadBirthdays() }
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
            // Round-25 fix: refresh whenever any repository mutation fires
            // `.routineDataChanged`. Without this, switching to Templates,
            // creating/activating a template, then switching back to Today
            // left `viewModel.activeTemplate` stuck at nil because iOS 18
            // TabView's `.onAppear` doesn't reliably re-fire when tabs
            // stay alive in the hierarchy.
            .onReceive(NotificationCenter.default.publisher(for: .routineDataChanged)) { _ in
                viewModel.reload()
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
