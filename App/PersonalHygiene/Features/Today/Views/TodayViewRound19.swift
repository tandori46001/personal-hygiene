import SwiftUI

/// Round-19 Today wires:
/// - T5.19 `tomorrowSection`: collapsed disclosure listing tomorrow's blocks
///   (next-day template). Renders nothing when no template exists for the
///   target day-type.
/// - T5.20 `moodQuickLogSection`: 5-emoji single-tap row that records a
///   mood entry into `MoodLogStore`, highlighting the most-recent today
///   entry so the user sees their selection persist across navigation.
extension TodayView {

    @ViewBuilder
    var tomorrowSection: some View {
        let blocks = viewModel.tomorrowBlocks()
        if !blocks.isEmpty {
            Section {
                DisclosureGroup {
                    ForEach(blocks) { block in
                        HStack {
                            Text(verbatim: Self.formattedTime(minutes: block.startMinutesFromMidnight))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                            Text(verbatim: block.title)
                                .font(.callout)
                            Spacer()
                            Text(localizedKey: "category.\(block.category.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } label: {
                    HStack {
                        Image(systemName: "sun.haze")
                            .foregroundStyle(.secondary)
                        Text("today.tomorrow.title", bundle: .main)
                        Spacer()
                        Text(verbatim: "\(blocks.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var moodQuickLogSection: some View {
        Section {
            HStack(spacing: 4) {
                ForEach(MoodLogStore.Mood.allCases, id: \.rawValue) { mood in
                    Button {
                        MoodLogStore.record(mood)
                    } label: {
                        Text(verbatim: mood.emoji)
                            .font(.title2)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(
                                MoodLogStore.todayEntry()?.mood == mood.rawValue
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(localizedKey: "today.mood.\(mood.rawValue)"))
                }
            }
            .frame(maxWidth: .infinity)
            // Round-20 slice T2.7: trailing 7-day "good days" caption.
            // Hidden when count is zero so the row stays empty for users who
            // haven't engaged yet.
            let goodCount = MoodLogStore.goodDaysCount()
            if goodCount > 0 {
                Text("today.mood.goodDaysWeek \(goodCount)", bundle: .main)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            // Round-22 slice T4.22: positive streak caption under the
            // chip row.
            moodStreakCaption
        } header: {
            Text("today.mood.title", bundle: .main)
        } footer: {
            Text("today.mood.footer", bundle: .main)
        }
    }

    static func formattedTime(minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// Round-20 slice T4.19: floating "Day reset · Undo" capsule. Hidden
    /// when no snapshot is in flight.
    @ViewBuilder
    var resetDayUndoOverlay: some View {
        if let snapshot = resetDaySnapshot {
            HStack(spacing: 12) {
                Text("today.resetDay.undo.message", bundle: .main)
                    .font(.caption)
                Button {
                    viewModel.undoResetDay(snapshot)
                    resetDaySnapshot = nil
                    resetDayUndoTimer?.cancel()
                } label: {
                    Text("common.undo", bundle: .main)
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)
        }
    }

    /// Round-20 slice T4.19: clears the reset-day undo overlay after 10s.
    /// Called whenever a snapshot is captured by `resetDay()`.
    func scheduleResetDayUndoExpiry() {
        resetDayUndoTimer?.cancel()
        resetDayUndoTimer = Task { @MainActor [self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if !Task.isCancelled {
                self.resetDaySnapshot = nil
            }
        }
    }
}
