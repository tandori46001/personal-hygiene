import SwiftUI

/// Round-21 TodayView wires:
/// - T2.9 `moodWeekStrip`: 7 emoji slots showing the dominant mood per day for
///   the trailing week. Days with no entry render as a faint dot.
/// - T6.33 `focusToggleRow`: ad-hoc "Focus on / off" toggle that flips a
///   user-default flag the rest of the app reads. Lives below the schedule
///   so it never replaces the existing scheduled-window detection.
/// - Caption helper: when `MoodWeeklyGoalStore.isActive()` is true, the
///   trailing-7-day count renders as `n / target` instead of the bare count.
extension TodayView {

    /// Round-22 slice T4.22: thin caption shown beneath the mood quick-log
    /// when the user has a 3+ day positive streak. Hidden otherwise so the
    /// row stays compact for new / disengaged users.
    @ViewBuilder
    var moodStreakCaption: some View {
        let streak = MoodLogStore.streakDays(atLeast: .okay)
        if streak >= 3 {
            Text("today.mood.streak \(streak)", bundle: .main)
                .font(.caption2)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    /// Round-22 slice T5.27 (extracted to keep TodayView body under
    /// SwiftLint's 300-line cap): progress summary row + the day-completion
    /// bar as a single view returned to the host body.
    @ViewBuilder
    func progressSummarySection(showingDetail: Binding<Bool>) -> some View {
        if viewModel.totalCount > 0 {
            Section {
                Button {
                    showingDetail.wrappedValue = true
                } label: {
                    ProgressSummaryRow(
                        done: viewModel.doneCount,
                        total: viewModel.totalCount,
                        nextBlock: viewModel.nextBlock()
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("today.summary.tapHint", bundle: .main))
                TodayDayCompletionBar(
                    done: viewModel.doneCount,
                    total: viewModel.totalCount
                )
            }
        }
    }

    @ViewBuilder
    var moodWeekStripSection: some View {
        let strip = TodayView.moodWeekStrip()
        if !strip.isEmpty {
            Section {
                HStack(spacing: 6) {
                    ForEach(strip, id: \.day) { cell in
                        VStack(spacing: 2) {
                            Text(verbatim: cell.symbol)
                                .font(.callout)
                            Text(verbatim: TodayView.weekdayInitial(for: cell.day))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("today.mood.weekStrip.a11y", bundle: .main))
            }
        }
    }

    @ViewBuilder
    var focusToggleRow: some View {
        Section {
            let binding = Binding<Bool>(
                get: { UserDefaults.standard.bool(forKey: TodayView.focusAdhocKey) },
                set: { UserDefaults.standard.set($0, forKey: TodayView.focusAdhocKey) }
            )
            Toggle(isOn: binding) {
                Label {
                    Text("today.focus.adhoc.title", bundle: .main)
                } icon: {
                    Image(systemName: "moon.circle")
                }
            }
        } footer: {
            Text("today.focus.adhoc.footer", bundle: .main)
        }
    }

    static let focusAdhocKey = "today.focusAdhoc"

    /// Round-21 slice T4.20: chains "skip today" with a 5-minute snooze
    /// marker so a single long-press takes the block off today's schedule
    /// AND records an undo-style snooze badge — useful for a quick "I'll
    /// come back to this" interaction. Caller wires this into the row's
    /// long-press / context menu.
    func skipPlusSnooze(_ block: Block, now: Date = Date(), snoozeStore: any BlockSnoozeStore) {
        viewModel.toggleSkippedToday(block, now: now)
        let dayKey = TodayView.dayKey(for: now)
        snoozeStore.markSnoozed(blockID: block.id, dayKey: dayKey)
    }

    static func dayKey(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// Round-21 slice T4.21: composes the toast text for `.refreshable`,
    /// appending the latest `RefreshTraceLog` summary when available so
    /// pull-to-refresh doubles as observability without visiting
    /// Diagnostics.
    @MainActor
    static func composedRefreshToast() -> String {
        let baseLine = String(localized: "today.refresh.done")
        if let trace = refreshTraceToastText() {
            return "\(baseLine) · \(trace)"
        }
        return baseLine
    }

    /// Round-21 slice T4.21: builds a single-line summary of the most-recent
    /// `RefreshTraceLog` entry suitable for a transient pull-to-refresh
    /// toast. Returns `nil` when no refresh has been recorded this session.
    @MainActor
    static func refreshTraceToastText() -> String? {
        guard let last = RefreshTraceLog.shared.entries.last else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        let kindLabel: String
        switch last.kind {
        case .refresh: kindLabel = "refresh"
        case .reschedule: kindLabel = "reschedule"
        case .paused: kindLabel = "paused"
        }
        return "\(formatter.string(from: last.timestamp)) · \(kindLabel) · \(last.scheduledCount)"
    }

    struct MoodWeekCell: Equatable {
        let day: Date
        /// Emoji or `·` placeholder when no entry for that day.
        let symbol: String
    }

    static func moodWeekStrip(
        entries: [MoodLogStore.Entry] = MoodLogStore.entries(),
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> [MoodWeekCell] {
        let bins = MoodTrendAggregator.bins(from: entries, days: 7, endingAt: now, calendar: calendar)
        return bins.map { bin in
            let symbol: String
            if let score = bin.score {
                symbol = MoodTrendAggregator.symbol(for: score)
            } else {
                symbol = "·"
            }
            return MoodWeekCell(day: bin.day, symbol: symbol)
        }
    }

    static func weekdayInitial(for day: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let weekday = calendar.component(.weekday, from: day)
        let symbols = calendar.veryShortWeekdaySymbols
        guard symbols.indices.contains(weekday - 1) else { return "" }
        return symbols[weekday - 1]
    }
}

// `MoodTrendAggregator.symbol(for:)` lives in `App/Shared/Services/MoodTrendAggregator.swift`
// so the watch target (which only compiles Shared/) can reuse it for the
// settings glance mood strip (round-22 slice T6.33).
