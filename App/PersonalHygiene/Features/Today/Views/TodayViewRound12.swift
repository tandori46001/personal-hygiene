import SwiftUI

extension TodayView {

    /// Round-18 slice 5: stale-day banner shown after the device time zone
    /// changes mid-session. Hosted in this extension to keep `TodayView`'s
    /// struct body under SwiftLint's 300-line cap.
    @ViewBuilder
    var staleDayBannerSection: some View {
        if staleDayBannerVisible {
            Section {
                Button {
                    staleDayBannerVisible = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("today.staleDay.title", bundle: .main)
                                .font(.callout.bold())
                            Text("today.staleDay.dismiss", bundle: .main)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Round-12 slice 23 + round-13 slice 22: filter shown blocks by the
    /// selected category and (optionally) collapse already-done blocks.
    func visibleBlocks(_ blocks: [Block], filter: BlockCategory?, collapseDone: Bool) -> [Block] {
        var filtered = blocks
        if let filter {
            filtered = filtered.filter { $0.category == filter }
        }
        if collapseDone {
            filtered = filtered.filter { !viewModel.isDone($0) }
        }
        return filtered
    }

    /// Round-13 slice 7: keep `nowMinutes` fresh every 60s while the view is
    /// foregrounded so the next-block caption stays accurate.
    static func makeMinuteTicker(_ updater: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                if Task.isCancelled { break }
                updater()
            }
        }
    }

    func shouldInsertNowMarker(
        before block: Block,
        in blocks: [Block],
        nowMinutes: Int
    ) -> Bool {
        guard let first = blocks.first, let last = blocks.last else { return false }
        let scheduleEnd = last.startMinutesFromMidnight + last.durationMinutes
        guard nowMinutes >= first.startMinutesFromMidnight, nowMinutes < scheduleEnd else {
            return false
        }
        guard let target = blocks.first(where: { $0.startMinutesFromMidnight > nowMinutes }) else {
            return false
        }
        return block.id == target.id
    }

    @ToolbarContentBuilder
    var todayToolbar: some ToolbarContent {
        // Round-25 slice T2.15: completion-percent chip in the topBarLeading
        // slot so the user reads progress at a glance without scrolling
        // back up to the summary row.
        ToolbarItem(placement: .topBarLeading) {
            TodayDayCompletionChip(
                done: viewModel.doneCount,
                total: viewModel.totalCount
            )
        }
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
                Button {
                    collapseDoneBlocks.toggle()
                } label: {
                    Label {
                        Text(
                            collapseDoneBlocks
                                ? "today.collapseDone.show"
                                : "today.collapseDone.hide",
                            bundle: .main
                        )
                    } icon: {
                        Image(systemName: collapseDoneBlocks ? "eye" : "eye.slash")
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
        // Round-21 slice T4.23: hidden iPad keyboard shortcut. ⌘D toggles
        // done on the current/next block — useful on a Magic Keyboard so
        // power users don't have to tap. Hidden via `.zero`/clear styling so
        // it doesn't visually duplicate the menu button.
        ToolbarItem(placement: .keyboard) {
            Button {
                if let target = viewModel.currentBlock() ?? viewModel.nextBlock() {
                    viewModel.toggleDone(target)
                }
            } label: {
                Text("today.shortcut.markDone", bundle: .main)
            }
            .keyboardShortcut("d", modifiers: [.command])
        }
    }
}

/// Round 27 redesign: previously a horizontal-scroll row that clipped
/// chips off both ends with up to 12 categories. Now a wrapping flow
/// layout with colored dots + per-category counts so every chip is
/// visible at a glance + the dot mirrors the row marker on each block.
struct CategoryFilterChips: View {
    @Binding var selected: BlockCategory?
    let blocks: [Block]

    private struct CountedCategory: Identifiable {
        let category: BlockCategory
        let count: Int
        var id: BlockCategory { category }
    }

    /// Categories that actually have blocks today, sorted by frequency
    /// (most-used first) so the filter is most useful at a glance.
    private var availableCategories: [CountedCategory] {
        var counts: [BlockCategory: Int] = [:]
        for block in blocks {
            counts[block.category, default: 0] += 1
        }
        return counts
            .map { CountedCategory(category: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.category.rawValue < rhs.category.rawValue
            }
    }

    var body: some View {
        FlowLayout(spacing: 6) {
            CategoryChip(
                label: Text("today.filter.all", bundle: .main),
                dotColor: nil,
                count: blocks.count,
                isSelected: selected == nil
            ) {
                selected = nil
            }
            ForEach(availableCategories) { entry in
                CategoryChip(
                    label: Text(localizedKey: "category.\(entry.category.rawValue)"),
                    dotColor: BlockCategoryColor.color(for: entry.category),
                    count: entry.count,
                    isSelected: selected == entry.category
                ) {
                    selected = (selected == entry.category) ? nil : entry.category
                }
            }
        }
    }
}

private struct CategoryChip: View {
    let label: Text
    let dotColor: Color?
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                }
                label
                    .font(.caption.bold())
                Text(verbatim: "\(count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background, in: Capsule())
            .overlay(
                Capsule().strokeBorder(borderColor, lineWidth: 1)
            )
            .foregroundStyle(Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(Text(verbatim: "\(count)"))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var background: Color {
        isSelected ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.12)
    }

    private var borderColor: Color {
        isSelected ? Color.accentColor : Color.clear
    }
}
