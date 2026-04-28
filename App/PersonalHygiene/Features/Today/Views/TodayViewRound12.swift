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
    }
}

/// Round-12 slice 23: horizontal scroll chips for filtering today by category.
struct CategoryFilterChips: View {
    @Binding var selected: BlockCategory?
    let blocks: [Block]

    private var availableCategories: [BlockCategory] {
        Array(Set(blocks.map(\.category))).sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button {
                    selected = nil
                } label: {
                    Text("today.filter.all", bundle: .main)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(selected == nil ? .accentColor : .secondary)
                ForEach(availableCategories, id: \.self) { cat in
                    Button {
                        selected = cat
                    } label: {
                        Text(localizedKey: "category.\(cat.rawValue)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(selected == cat ? .accentColor : .secondary)
                }
            }
        }
    }
}
